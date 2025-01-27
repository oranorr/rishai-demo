import 'dart:core';
import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:rishai/core/errors/failure.dart';
import 'package:rishai/core/usecase/usecase.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
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
    required this.restrictions,
    required this.calorieTarget,
    required this.macros,
    required this.trainingToday,
    required this.servings,
    required this.snackForToday,
  });
  final List<String> dietary;
  final List<String> cuisines;
  final List<String> restrictions;
  final int calorieTarget;
  final MacrosBreakdown macros;
  final bool trainingToday;
  final List<ServingEntity> servings;
  final bool snackForToday;

  List<Map<ServingType, String>> generatePrompt() {
    List<Map<String, dynamic>> generalMeals = [];
    Map<String, dynamic>? snack;
    Map<String, dynamic>? breakfast;
    Map<String, String> userPrefs = {
      'dietary_preferences': dietary.join(', '),
      'cuisine_preferences': cuisines.join(', '),
      'restrictions': restrictions.join(', '),
    };

    // Инициализируем переменные
    List<double> mealDistribution = [];
    bool snackRequested = snackForToday;
    bool hadTraining = trainingToday;
    MacrosBreakdown macross = macros;

    double totalCalories = macross.kcal.toDouble();
    double totalProtein = macross.protein.toDouble();
    double totalCarbs = macross.carbs.toDouble();
    double totalFats = macross.fat.toDouble();

    // Распределяем проценты в зависимости от условий
    if (servings.length == 2) {
      mealDistribution = snackRequested ? [50, 40, 10] : [60, 40];
    } else if (servings.length == 3) {
      mealDistribution = hadTraining
          ? (snackRequested ? [40, 30, 20, 10] : [45, 30, 25])
          : (snackRequested ? [35, 30, 25, 10] : [40, 35, 25]);
    } else if (servings.length == 4) {
      mealDistribution = hadTraining
          ? (snackRequested ? [26.5, 22.5, 21.5, 19.5, 10] : [30, 25, 24, 21])
          : (snackRequested ? [24.5, 23.5, 22.5, 19.5, 10] : [27, 26, 25, 22]);
    } else {
      double percent =
          snackRequested ? (100 - 10) / servings.length : 100 / servings.length;
      mealDistribution = List.filled(servings.length, percent);
      if (snackRequested) {
        mealDistribution = List.filled(servings.length, percent).toList()
          ..add(10);
      } else {
        mealDistribution = List.filled(servings.length, percent).toList();
      }
    }

    // Корректируем суммарное распределение (точность до 100%)
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

    // Обрабатываем servings
    for (int i = 0; i < servings.length; i++) {
      final serving = servings[i];
      final mealData = {
        'type': serving.type.name,
        'calories': '${mealCalories[i].round()} kcal',
        'protein': '${proteinDistribution[i].round()} g',
        'carbs': '${carbsDistribution[i].round()} g',
        'fats': '${fatsDistribution[i].round()} g',
      };

      if (serving.type == ServingType.breakfast) {
        breakfast = {
          ...userPrefs,
          'type': '${serving.comment} ${serving.type.name}',
          ...mealData,
        };
      } else if (serving.type == ServingType.snack) {
        snack = {
          ...userPrefs,
          'type': '${serving.comment} ${serving.type.name}',
          ...mealData,
        };
      } else {
        generalMeals.add(mealData);
      }
    }

    // Возвращаем итог
    return [
      if (breakfast != null)
        {
          ServingType.breakfast:
              'generate_meal_plan_for_me. My data is: $breakfast',
        },
      if (generalMeals.isNotEmpty)
        {
          ServingType.dinner:
              'generate_meal_plan_for_me. My data is: $userPrefs, meals: $generalMeals',
        },
      if (snack != null)
        {
          ServingType.snack: 'generate_meal_plan_for_me. My data is: $snack',
        },
    ];
  }

  @override
  String toString() {
    return 'RequestPlanParams(dietary: $dietary, cuisines: $cuisines, calorieTarget: $calorieTarget, macros: $macros, trainingToday: $trainingToday, servings: $servings, snackForToday: $snackForToday)';
  }
}

    // }

//     return '''
// generate_meal_plan_for_me. My data is: 
// {
//   "dietary_preferences": $dietary,
//   "cuisine_preferences": $cuisines,
//   "meals": $meals,
//   ${snackForToday ? '$snackType: $snack' : ''}
// }
// ''';


// class PromptGeneratorTester {
//   final List<RequestPlanParams> params = [
//     RequestPlanParams(
//       dietary: [],
//       cuisines: [],
//       calorieTarget: 3053,
//       macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
//       trainingToday: false,
//       snackForToday: false,
//       mealTypes: ['breakfast', 'lunch'],
//       restrictions: [],
//     ),
//     RequestPlanParams(
//       dietary: [],
//       cuisines: [],
//       calorieTarget: 3053,
//       macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
//       trainingToday: false,
//       snackForToday: false,
//       mealTypes: ['breakfast', 'lunch', 'dinner'],
//       restrictions: [],
//     ),
//     RequestPlanParams(
//       dietary: [],
//       cuisines: [],
//       calorieTarget: 3053,
//       macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
//       trainingToday: false,
//       snackForToday: false,
//       mealTypes: ['breakfast', 'lunch', 'dinner', 'supper'],
//       restrictions: [],
//     ),
//   ];

//   void test() {
//     for (final request in params) {
//       log(request.generatePrompt());
//     }
//   }
// }
