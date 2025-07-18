import 'dart:core';
import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/data/remote_data_source/llm_proxy_client.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';
import 'package:rishai/features/whoop/domain/entities/day_entity.dart';

/// Новый UseCase для работы с новой структурой API
@injectable
class RequestPlanUsecaseV2
    implements UseCase<MealPlanEntity, RequestPlanParams> {
  RequestPlanUsecaseV2(
    this.chatRepository,
  );
  final ChatRepository chatRepository;

  @override
  Future<Either<Failure, MealPlanEntity>> call(RequestPlanParams params) async {
    return chatRepository.requestMealPlanV2(params: params);
  }
}

class RequestPlanParams {
  RequestPlanParams({
    required this.dietary,
    required this.cuisines,
    required this.restrictions,
    required this.calorieTarget,
    required this.macros,
    required this.trainingToday,
    required this.servings,
    required this.snackForToday,
    required this.isWeekPlan,
    this.excludedMeals,
  });
  final List<String> dietary;
  final List<String> cuisines;
  final List<String> restrictions;
  final int calorieTarget;
  final MacrosBreakdown macros;
  final bool trainingToday;
  final List<ServingEntity> servings;
  final bool snackForToday;
  final bool isWeekPlan;
  final Map<String, List<String>>? excludedMeals;

  /// Генерирует запросы блюд для новой структуры API
  List<LlmMealRequest> generateMealRequests() {
    log('[generateMealRequests] Начинаем генерацию запросов блюд');
    log(toString());

    final days = userBloc.state.days;
    final alreadyGeneratedMeals =
        isWeekPlan ? excludedMeals : DayEntity.getMealHistory(days);

    if (dietary.contains('Carnivore')) {
      dietary.remove('Carnivore');
    }

    final userPrefs = {
      'dietary_preferences': dietary.join(', '),
      'cuisine_preferences': cuisines.join(', '),
      'restrictions': restrictions.join(', '),
    };

    // Инициализируем переменные для расчета макросов
    List<double> mealDistribution = [];
    bool snackRequested = snackForToday;
    bool hadTraining = trainingToday;
    MacrosBreakdown macross = macros;

    double totalCalories = macross.kcal.toDouble();
    double totalProtein = macross.protein.toDouble();
    double totalCarbs = macross.carbs.toDouble();
    double totalFats = macross.fat.toDouble();

    int length = snackRequested ? servings.length - 1 : servings.length;

//     3 питания + снек, без активности
// ожидаемый : 35%+30%+25%+10%
// фактический 35%+25%+30%+10%

    // Распределяем проценты калорий между приемами пищи
    if (length == 2) {
      mealDistribution = hadTraining
          ? (snackRequested ? [50, 40, 10] : [60, 40]) // с тренировкой
          : (snackRequested ? [50, 40, 10] : [60, 40]); // без тренировки
    } else if (length == 3) {
      mealDistribution = hadTraining
          ? (snackRequested ? [40, 30, 20, 10] : [45, 30, 25]) // с тренировкой
          : (snackRequested
              ? [35, 30, 25, 10]
              : [40, 35, 25]); // без тренировки
    } else if (length == 4) {
      mealDistribution = hadTraining
          ? (snackRequested
              ? [26.5, 22.5, 21.5, 19.5, 10]
              : [30, 25, 24, 21]) // с тренировкой
          : (snackRequested
              ? [24.5, 23.5, 22.5, 19.5, 10]
              : [27, 26, 25, 22]); // без тренировки
    }
    // Корректируем суммарное распределение
    double totalMealDistribution = mealDistribution.reduce((a, b) => a + b);
    double difference = 100 - totalMealDistribution;
    if (difference.abs() > 0.1) {
      mealDistribution[mealDistribution.length - 1] += difference;
    }

    // Распределяем калории и макросы
    List<double> mealCalories = mealDistribution
        .map((percent) => totalCalories * percent / 100)
        .toList();
    List<double> proteinDistribution = mealDistribution
        .map((percent) => totalProtein * percent / 100)
        .toList();
    List<double> carbsDistribution =
        mealDistribution.map((percent) => totalCarbs * percent / 100).toList();
    List<double> fatsDistribution =
        mealDistribution.map((percent) => totalFats * percent / 100).toList();

    // Группируем блюда по типам запросов
    List<LlmMealDto> breakfastMeals = [];
    List<LlmMealDto> mainMeals = [];
    List<LlmMealDto> snackMeals = [];

    for (int i = 0; i < servings.length; i++) {
      final serving = servings[i];

      // Создаем DTO для блюда с правильным форматированием типа
      final mealDto = LlmMealDto(
        type: _formatMealType(serving),
        kcal: mealCalories[i].round(),
        protein: proteinDistribution[i].round(),
        carbs: carbsDistribution[i].round(),
        fat: fatsDistribution[i].round(),
      );

      // Группируем по типам запросов
      if (serving.type == ServingType.breakfast) {
        breakfastMeals.add(mealDto);
      } else if (serving.type == ServingType.snack) {
        snackMeals.add(mealDto);
      } else {
        // lunch, dinner, supper идут в один запрос типа "meal"
        mainMeals.add(mealDto);
      }
    }

    // Создаем список запросов
    List<LlmMealRequest> requests = [];

    // Запрос для завтрака
    if (breakfastMeals.isNotEmpty) {
      final excludedBreakfasts = alreadyGeneratedMeals?['breakfasts'] ?? [];

      // Формируем информацию о блюдах для промпта
      final mealsInfo = breakfastMeals
          .map(
            (meal) => {
              'calories': '${meal.kcal} kcal',
              'protein': '${meal.protein} g',
              'carbs': '${meal.carbs} g',
              'fats': '${meal.fat} g',
              'type': meal.type,
            },
          )
          .toList();

      final message =
          'generate_meal_plan_for_me. My data is: $userPrefs, meals: $mealsInfo. Please exclude following meals: $excludedBreakfasts';

      requests.add(
        LlmMealRequest(
          type: LlmMealRequestType.breakfast,
          message: message,
          meals: breakfastMeals,
        ),
      );

      log('[generateMealRequests] Добавлен запрос завтрака: ${breakfastMeals.length} блюд');
    }

    // Запрос для основных блюд (lunch, dinner, supper)
    if (mainMeals.isNotEmpty) {
      final excludedMains = alreadyGeneratedMeals?['mains'] ?? [];

      // Формируем информацию о блюдах для промпта
      final mealsInfo = mainMeals
          .map(
            (meal) => {
              'calories': '${meal.kcal} kcal',
              'protein': '${meal.protein} g',
              'carbs': '${meal.carbs} g',
              'fats': '${meal.fat} g',
              'type': meal.type,
            },
          )
          .toList();

      final message =
          'generate_meal_plan_for_me. My data is: $userPrefs, meals: $mealsInfo. Please exclude following meals: $excludedMains';

      requests.add(
        LlmMealRequest(
          type: LlmMealRequestType.meal,
          message: message,
          meals: mainMeals,
        ),
      );

      log('[generateMealRequests] Добавлен запрос основных блюд: ${mainMeals.length} блюд');
    }

    // Запрос для перекусов
    if (snackMeals.isNotEmpty) {
      final excludedSnacks = alreadyGeneratedMeals?['snacks'] ?? [];

      // Формируем информацию о блюдах для промпта
      final mealsInfo = snackMeals
          .map(
            (meal) => {
              'calories': '${meal.kcal} kcal',
              'protein': '${meal.protein} g',
              'carbs': '${meal.carbs} g',
              'fats': '${meal.fat} g',
              'type': meal.type,
            },
          )
          .toList();

      final message =
          'generate_meal_plan_for_me. My data is: $userPrefs, meals: $mealsInfo. Please exclude following meals: $excludedSnacks';

      requests.add(
        LlmMealRequest(
          type: LlmMealRequestType.snack,
          message: message,
          meals: snackMeals,
        ),
      );

      log('[generateMealRequests] Добавлен запрос перекусов: ${snackMeals.length} блюд');
    }

    log('[generateMealRequests] Создано ${requests.length} запросов блюд');
    return requests;
  }

  /// Форматирует тип блюда согласно новому API
  String _formatMealType(ServingEntity serving) {
    switch (serving.type) {
      case ServingType.breakfast:
        // "Savoury Breakfast" или "Sweet Breakfast"
        final comment = serving.comment?.trim() ?? '';
        return comment.isNotEmpty ? '$comment Breakfast' : 'Breakfast';
      case ServingType.snack:
        // "Savoury Snack" или "Sweet Snack"
        final comment = serving.comment?.trim() ?? '';
        return comment.isNotEmpty ? '$comment Snack' : 'Snack';
      case ServingType.lunch:
        return 'Lunch';
      case ServingType.dinner:
        return 'Dinner';
      case ServingType.supper:
        return 'Supper';
      default:
        throw ArgumentError('Неподдерживаемый тип блюда: ${serving.type}');
    }
  }

  /// Публичный метод для генерации запросов блюд с новой структурой API
  List<LlmMealRequest> generateMealRequestsV2() {
    return generateMealRequests();
  }

  @override
  String toString() {
    return 'RequestPlanParams(dietary: $dietary, cuisines: $cuisines, calorieTarget: $calorieTarget, macros: $macros, trainingToday: $trainingToday, servings: $servings, snackForToday: $snackForToday)';
  }
}

//fb app id: 1:586052816326:ios:4512f65356dee6f637b6c7
//adapty id: XiRqmipkRzSZL8FCRbPcww
