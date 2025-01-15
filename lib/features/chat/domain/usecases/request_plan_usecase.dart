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
    required this.mealTypes,
    required this.snackForToday,
  });
  final List<String> dietary;
  final List<String> cuisines;
  final int calorieTarget;
  final MacrosBreakdown macros;
  final bool trainingToday;
  final List<String> mealTypes;
  final bool snackForToday;

  String generatePrompt() {
    log(toString());
    List<Map<String, dynamic>> meals = [];
    Map<String, dynamic>? snack;
    List<double> mealDistribution = [];

    bool snackRequested = snackForToday;
    bool hadTraining = trainingToday;
    int amountOfMeals = mealTypes.length;
    MacrosBreakdown macross = macros;
    String? snackType = mealTypes.firstWhere(
      (meal) => meal == 'Savoury Snack' || meal == 'Sweet Snack',
      orElse: () => '',
    );

    double totalCalories = macross.kcal.toDouble();
    double totalProtein = macross.protein.toDouble();
    double totalCarbs = macross.carbs.toDouble();
    double totalFats = macross.fat.toDouble();

    // Определяем распределение калорий по типам блюд, включая перекус
    if (amountOfMeals == 2) {
      if (snackRequested) {
        mealDistribution = [50, 40, 10];
      } else {
        mealDistribution = [60, 40];
      }
    } else if (amountOfMeals == 3) {
      if (hadTraining) {
        if (snackRequested) {
          mealDistribution = [40, 30, 20, 10];
        } else {
          mealDistribution = [45, 30, 25];
        }
      } else {
        if (snackRequested) {
          mealDistribution = [35, 30, 25, 10];
        } else {
          mealDistribution = [40, 35, 25];
        }
      }
    } else if (amountOfMeals == 4) {
      if (hadTraining) {
        if (snackRequested) {
          mealDistribution = [26.5, 22.5, 21.5, 19.5, 10];
        } else {
          mealDistribution = [30, 25, 24, 21];
        }
      } else {
        if (snackRequested) {
          mealDistribution = [24.5, 23.5, 22.5, 19.5, 10];
        } else {
          mealDistribution = [27, 26, 25, 22];
        }
      }
    } else {
      double percent =
          snackRequested ? (100 - 10) / amountOfMeals : 100 / amountOfMeals;
      mealDistribution = List.filled(amountOfMeals, percent);
      if (snackRequested) {
        mealDistribution.add(10);
      }
    }

    double totalMealDistribution = mealDistribution.reduce((a, b) => a + b);
    double expectedTotal = 100;
    double difference = expectedTotal - totalMealDistribution;
    if (difference != 0) {
      mealDistribution[mealDistribution.length - 1] += difference;
    }

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

    for (int i = 0; i < amountOfMeals; i++) {
      if (mealTypes[i] != 'Savoury Snack' && mealTypes[i] != 'Sweet Snack') {
        meals.add({
          'type': mealTypes[i],
          'calories': '${mealCalories[i].round()} kcal',
          'protein': '${proteinDistribution[i].round()} g',
          'carbs': '${carbsDistribution[i].round()} g',
          'fats': '${fatsDistribution[i].round()} g',
        });
      }
    }

    if (snackRequested) {
      int snackIndex = mealCalories.length - 1;
      snack = {
        'calories': '${mealCalories[snackIndex].round()} kcal',
        'protein': '${proteinDistribution[snackIndex].round()} g',
        'carbs': '${carbsDistribution[snackIndex].round()} g',
        'fats': '${fatsDistribution[snackIndex].round()} g',
      };
    }

    return '''
generate_meal_plan_for_me. My data is: 
{
  "dietary_preferences": $dietary,
  "cuisine_preferences": $cuisines,
  "meals": $meals,
  ${snackForToday ? '$snackType: $snack' : ''}
}
''';
  }

  @override
  String toString() {
    return 'RequestPlanParams(dietary: $dietary, cuisines: $cuisines, calorieTarget: $calorieTarget, macros: $macros, trainingToday: $trainingToday, mealTypes: $mealTypes, snackForToday: $snackForToday)';
  }
}

class PromptGeneratorTester {
  final List<RequestPlanParams> params = [
    RequestPlanParams(
      dietary: [],
      cuisines: [],
      calorieTarget: 3053,
      macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
      trainingToday: false,
      snackForToday: false,
      mealTypes: ['breakfast', 'lunch'],
    ),
    RequestPlanParams(
      dietary: [],
      cuisines: [],
      calorieTarget: 3053,
      macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
      trainingToday: false,
      snackForToday: false,
      mealTypes: ['breakfast', 'lunch', 'dinner'],
    ),
    RequestPlanParams(
      dietary: [],
      cuisines: [],
      calorieTarget: 3053,
      macros: MacrosBreakdown(kcal: 3053, protein: 157, carbs: 444, fat: 72),
      trainingToday: false,
      snackForToday: false,
      mealTypes: ['breakfast', 'lunch', 'dinner', 'supper'],
    ),
  ];

  void test() {
    for (final request in params) {
      log(request.generatePrompt());
    }
  }
}
