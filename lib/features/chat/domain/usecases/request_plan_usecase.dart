import 'dart:core';
import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/repository/chat_repository.dart';

@injectable
class RequestPlanUsecase implements UseCase<MealPlanEntity, RequestPlanParams> {
  RequestPlanUsecase(
    this.chatRepository,
  );
  final ChatRepository chatRepository;
  @override
  Future<Either<Failure, MealPlanEntity>> call(RequestPlanParams params) async {
    return chatRepository.requestMealPlan(params: params);
  }
}

class RequestPlanParams {
  RequestPlanParams({
    required this.dietary,
    required this.cuisines,
    required this.calorieTarget,
    required this.macros,
    required this.trainingToday,
    required this.mealsAmount,
    required this.snackForToday,
  });
  final List<String> dietary;
  final List<String> cuisines;
  final int calorieTarget;
  final MacrosBreakdown macros;
  final bool trainingToday;
  final int mealsAmount;
  final bool snackForToday;

  String generatePrompt() {
    log(toString());
    List<Map<String, dynamic>> meals = [];
    Map<String, dynamic>? snack;
    List<double> mealDistribution = [];

    // Предполагается, что эти переменные определены в контексте
    bool snackRequested = snackForToday;
    bool hadTraining = trainingToday; // Например, true или false
    int amountOfMeals = mealsAmount;
    /* ваше значение */ // Например, 3
    MacrosBreakdown macross = macros;
    /* ваш объект макросов */ // Объект с полями kcal, protein, carbs, fat

    double totalCalories = macross.kcal.toDouble();
    double totalProtein = macross.protein.toDouble();
    double totalCarbs = macross.carbs.toDouble();
    double totalFats = macross.fat.toDouble();

    // Определяем распределение калорий по блюдам, включая перекус
    if (amountOfMeals == 2) {
      if (snackRequested) {
        // mealDistribution = [45, 45, 10];
        mealDistribution = [50, 40, 10];
      } else {
        mealDistribution = [60, 40];
        // mealDistribution = [50, 50];
      }
    } else if (amountOfMeals == 3) {
      if (hadTraining) {
        if (snackRequested) {
          // С перекусом и тренировкой: [20, 20, 40, 10]
          mealDistribution = [40, 30, 20, 10];
        } else {
          // Без перекуса, но с тренировкой: [40, 30, 30]
          mealDistribution = [45, 30, 25];
        }
      } else {
        if (snackRequested) {
          // С перекусом без тренировки: [30, 30, 30, 10]
          // mealDistribution = [30, 30, 30, 10];
          mealDistribution = [35, 30, 25, 10];
        } else {
          // Без тренировки и без перекуса: [33.3, 33.3, 33.4]
          // mealDistribution = [33.3, 33.3, 33.4];
          mealDistribution = [40, 35, 25];
        }
      }
    } else if (amountOfMeals == 4) {
      if (hadTraining) {
        if (snackRequested) {
          // С перекусом и тренировкой: [20, 20, 20, 30, 10]
          // mealDistribution = [20, 20, 20, 30, 10];
          mealDistribution = [26.5, 22.5, 21.5, 19.5, 10];
        } else {
          // Без перекуса, но с тренировкой: [10, 25, 25, 40]
          // mealDistribution = [10, 25, 25, 40];
          mealDistribution = [30, 25, 24, 21];
        }
      } else {
        if (snackRequested) {
          // С перекусом без тренировки: [22.5, 22.5, 22.5, 22.5, 10]
          // mealDistribution = [22.5, 22.5, 22.5, 22.5, 10];
          mealDistribution = [24.5, 23.5, 22.5, 19.5, 10];
        } else {
          // Без тренировки и без перекуса: [25, 25, 25, 25]
          // mealDistribution = [25, 25, 25, 25];
          mealDistribution = [27, 26, 25, 22];
        }
      }
    } else {
      // Для других количеств приёмов пищи
      double percent =
          snackRequested ? (100 - 10) / amountOfMeals : 100 / amountOfMeals;
      mealDistribution = List.filled(amountOfMeals, percent);
      if (snackRequested) {
        mealDistribution.add(10); // Добавляем 10% на перекус
      }
    }

    // Проверяем, чтобы сумма процентов была 100%
    double totalMealDistribution = mealDistribution.reduce((a, b) => a + b);
    double expectedTotal = 100;
    double difference = expectedTotal - totalMealDistribution;
    if (difference != 0) {
      // Корректируем последний элемент, чтобы сумма была правильной
      mealDistribution[mealDistribution.length - 1] += difference;
    }

    // Распределяем калории и макронутриенты по всем блюдам (включая перекус)
    List<double> mealCalories = mealDistribution
        .map((percent) => totalCalories * percent / 100)
        .toList();

    List<double> proteinDistribution = mealDistribution
        .map((percent) => totalProtein * percent / 100)
        .toList();

    List<double> fatsDistribution =
        mealDistribution.map((percent) => totalFats * percent / 100).toList();

    List<double> carbsDistribution =
        mealDistribution.map((percent) => totalCarbs * percent / 100).toList();

    // Формируем список основных блюд (без перекуса)
    for (int i = 0; i < amountOfMeals; i++) {
      meals.add({
        'calories': '${mealCalories[i].round()} kcal',
        'protein': '${proteinDistribution[i].round()} g',
        'carbs': '${carbsDistribution[i].round()} g',
        'fats': '${fatsDistribution[i].round()} g',
      });
    }

    // Если есть снек, извлекаем его из последних значений
    if (snackRequested) {
      int snackIndex = mealCalories.length - 1;
      snack = {
        'calories': '${mealCalories[snackIndex].round()} kcal',
        'protein': '${proteinDistribution[snackIndex].round()} g',
        'carbs': '${carbsDistribution[snackIndex].round()} g',
        'fats': '${fatsDistribution[snackIndex].round()} g',
      };
    }

    // Генерация текста промпта
    return '''
generate_meal_plan_for_me. My data is: 
{
  "dietary_preferences": $dietary,
  "cuisine_preferences": $cuisines,
  "meals": $meals,
  ${snackForToday ? '"snack": $snack' : ''}
}
''';
  }

  @override
  String toString() {
    return 'RequestPlanParams(dietary: $dietary, cuisines: $cuisines, calorieTarget: $calorieTarget, macros: $macros, trainingToday: $trainingToday, mealsAmount: $mealsAmount, snackForToday: $snackForToday)';
  }
}

class PromptGeneratorTester {
  final List<RequestPlanParams> params = [
    //
    RequestPlanParams(
      dietary: [],
      cuisines: [],
      calorieTarget: 3053,
      macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
      trainingToday: false,
      snackForToday: false,
      mealsAmount: 2,
    ),
    // RequestPlanParams(
    //   dietary: [],
    //   cuisines: [],
    //   calorieTarget: 3053,
    //   macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
    //   trainingToday: true,
    //   snackForToday: false,
    //   mealsAmount: 2,
    // ),
    // RequestPlanParams(
    //   dietary: [],
    //   cuisines: [],
    //   calorieTarget: 3053,
    //   macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
    //   trainingToday: false,
    //   snackForToday: true,
    //   mealsAmount: 2,
    // ),
    // RequestPlanParams(
    //   dietary: [],
    //   cuisines: [],
    //   calorieTarget: 3053,
    //   macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
    //   trainingToday: true,
    //   snackForToday: true,
    //   mealsAmount: 2,
    // ),

    //3
    RequestPlanParams(
      dietary: [],
      cuisines: [],
      calorieTarget: 3053,
      macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
      trainingToday: false,
      snackForToday: false,
      mealsAmount: 3,
    ),
    // RequestPlanParams(
    //   dietary: [],
    //   cuisines: [],
    //   calorieTarget: 3053,
    //   macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
    //   trainingToday: true,
    //   snackForToday: false,
    //   mealsAmount: 3,
    // ),
    // RequestPlanParams(
    //   dietary: [],
    //   cuisines: [],
    //   calorieTarget: 3053,
    //   macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
    //   trainingToday: false,
    //   snackForToday: true,
    //   mealsAmount: 3,
    // ),
    // RequestPlanParams(
    //   dietary: [],
    //   cuisines: [],
    //   calorieTarget: 3053,
    //   macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
    //   trainingToday: true,
    //   snackForToday: true,
    //   mealsAmount: 3,
    // ),

    //
    RequestPlanParams(
      dietary: [],
      cuisines: [],
      calorieTarget: 3053,
      macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
      trainingToday: false,
      snackForToday: false,
      mealsAmount: 4,
    ),
    // RequestPlanParams(
    //   dietary: [],
    //   cuisines: [],
    //   calorieTarget: 3053,
    //   macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
    //   trainingToday: true,
    //   snackForToday: false,
    //   mealsAmount: 4,
    // ),
    // RequestPlanParams(
    //   dietary: [],
    //   cuisines: [],
    //   calorieTarget: 3053,
    //   macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
    //   trainingToday: false,
    //   snackForToday: true,
    //   mealsAmount: 4,
    // ),
    // RequestPlanParams(
    //   dietary: [],
    //   cuisines: [],
    //   calorieTarget: 3053,
    //   macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
    //   trainingToday: true,
    //   snackForToday: true,
    //   mealsAmount: 4,
    // ),
  ];

  void test() {
    for (final request in params) {
      log(request.generatePrompt());
    }
  }
}


// RequestPlanParams(dietary: [], cuisines: [], calorieTarget: 3053, macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72), trainingToday: true, mealsAmount: 3, snackForToday: true)
// [log] generate_meal_plan_for_me. My data is: 
//       {
//         "dietary_preferences": [],
//         "cuisine_preferences": [],
//         "meals": [{calories: 611 kcal, protein: 31 g, carbs: 89 g, fats: 14 g}, {calories: 611 kcal, protein: 31 g, carbs: 89 g, fats: 14 g}, {calories: 1221 kcal, protein: 63 g, carbs: 178 g, fats: 29 g}],
//         "snack": {calories: 611 kcal, protein: 31 g, carbs: 89 g, fats: 14 g}
//       }

//должно быть 40-30-20-10
