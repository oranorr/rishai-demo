// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/user/domain/entities/user_entity.dart';
import 'package:rishai/features/whoop/data/models/workout_model.dart';
import 'package:rishai/features/whoop/domain/entities/activity.dart';
import 'package:rishai/features/whoop/presentation/calculate.dart';

part 'user_data_entity.g.dart';

@HiveType(typeId: 13)
class UserDataEntity {
  @HiveField(0)
  final List<WorkoutModel> workouts;
  @HiveField(1)
  final double userWeightLbs;
  @HiveField(2)
  final Gender gender;
  @HiveField(3)
  final double strainValue;
  @HiveField(4)
  final int recoveryScore;
  @HiveField(5)
  final int sleepPerformance;
  @HiveField(6)
  final int calorieGoal;
  @HiveField(7)
  final DateTime askTime;
  @HiveField(8)
  final String userId;
  @HiveField(9)
  final int currentCycleId;

  UserDataEntity({
    required this.workouts,
    required this.userWeightLbs,
    required this.gender,
    required this.strainValue,
    required this.recoveryScore,
    required this.sleepPerformance,
    required this.calorieGoal,
    required this.askTime,
    required this.userId,
    required this.currentCycleId,
  });

  int calcProteins() {
    final calc = CalculateWhoopData(
      gender: gender,
      strainValue: strainValue,
      recoveryScore: recoveryScore,
      sleepPerformance: sleepPerformance,
    );

    double proteins = 0;
    if (workouts.isEmpty) {
      proteins = ((0.6 * calc.calcStrain().protein) +
              (0.3 * calc.calculateRecovery().protein) +
              (0.1 * calc.calculateSleepPerformance().protein)) *
          userWeightLbs;
    } else if (workouts.length == 1) {
      // Proteins = ((0,5*значение P из таблицы Activity type в зависимости от типа активности)+
      //(0,3*значение P из таблицы Strain)+
      //(0,1*значение P из таблицы Recovery range)+
      //(0,1*значение P из таблицы Sleep Performance))
      //*вес пользователя в фунтах
      proteins = ((0.5 *
                  calc
                      .calcActivity(
                        activity: getActivity(workouts.first.sportId),
                      )
                      .protein) +
              (0.3 * calc.calcStrain().protein) +
              (0.1 * calc.calculateRecovery().protein) +
              (0.1 * calc.calculateSleepPerformance().protein)) *
          userWeightLbs;
      return proteins.round();
    } else if (workouts.length > 1) {
      for (final WorkoutModel workout in workouts) {
        proteins += ((0.5 *
                    calc
                        .calcActivity(activity: getActivity(workout.sportId))
                        .protein) +
                (0.3 * calc.calcStrain().protein) +
                (0.1 * calc.calculateRecovery().protein) +
                (0.1 * calc.calculateSleepPerformance().protein)) *
            userWeightLbs;
      }
      return (proteins / workouts.length).round();
    } else {
      log('ERROR WHILE CALC PROTEINS');
      return proteins.round();
    }
    return proteins.round();
  }

  int clacFats() {
    final calc = CalculateWhoopData(
      gender: gender,
      strainValue: strainValue,
      recoveryScore: recoveryScore,
      sleepPerformance: 0,
    );

    final res = ((0.5 * calc.calcStrain().fats) +
            (0.5 * calc.calculateRecovery().fats)) *
        userWeightLbs;
    return res.round();
  }

  int calcCarbs({
    required int kalorieGoal,
    required int proteinsInKcal,
    required int fatsInKcal,
  }) {
    int carbsInCals = kalorieGoal - proteinsInKcal - fatsInKcal;
    double carbs = carbsInCals / 4;
    return carbs.round();
  }

  MacrosBreakdown calcMacros() {
    log('Calculating macros with userWeightLbs: $userWeightLbs, calorieGoal: $calorieGoal, gender: $gender');

    // Проверка на нулевой вес
    if (userWeightLbs <= 0) {
      log('WARNING: userWeightLbs is zero or negative: $userWeightLbs');

      // Возвращаем стандартное распределение макросов
      final standardProtein =
          (0.3 * calorieGoal / 4).round(); // 30% калорий от белка
      final standardFat =
          (0.2 * calorieGoal / 9).round(); // 20% калорий от жиров
      final standardCarbs =
          (0.5 * calorieGoal / 4).round(); // 50% калорий от углеводов

      log('Using standard macros distribution: P=$standardProtein, C=$standardCarbs, F=$standardFat');

      return MacrosBreakdown(
        kcal: calorieGoal,
        protein: standardProtein,
        carbs: standardCarbs,
        fat: standardFat,
      );
    }

    final protein = calcProteins();
    final fats = clacFats();

    log('Calculated protein: $protein, fats: $fats');

    final carbs = calcCarbs(
      kalorieGoal: calorieGoal,
      proteinsInKcal: protein * 4,
      fatsInKcal: fats * 9,
    );

    // Проверка на нулевые значения
    final validProtein =
        protein > 0 ? protein : (0.3 * calorieGoal / 4).round();
    final validFat = fats > 0 ? fats : (0.2 * calorieGoal / 9).round();
    final validCarbs = carbs > 0 ? carbs : (0.5 * calorieGoal / 4).round();

    if (protein == 0 || fats == 0 || carbs == 0) {
      log('WARNING: One or more macro values are zero. Using valid values instead.');
      log('Original values - protein: $protein, carbs: $carbs, fat: $fats');
      log('Fixed values - protein: $validProtein, carbs: $validCarbs, fat: $validFat');
    }

    return MacrosBreakdown(
      kcal: calorieGoal,
      protein: validProtein,
      carbs: validCarbs,
      fat: validFat,
    );
  }

  /// Утилитарный метод для проверки нужны ли специальные макросы для диеты
  static bool needsNewMacrosOnDietChange(List<String> userDiets) {
    return userDiets.any(
      (diet) =>
          diet.toLowerCase() == 'keto' || diet.toLowerCase() == 'carnivore',
    );
  }

  /// Проверяет, содержит ли список диет CARNIVORE
  static bool hasCarnivore(List<String> userDiets) {
    return userDiets.any(
      (diet) => diet.toLowerCase() == 'carnivore',
    );
  }

  /// Проверяет, содержит ли список диет KETO
  static bool hasKeto(List<String> userDiets) {
    return userDiets.any(
      (diet) => diet.toLowerCase() == 'keto',
    );
  }

  /// Определяет тип специальной диеты на основе приоритета
  /// Возвращает: 'carnivore', 'keto' или null для стандартных диет
  static String? getSpecialDietType(List<String> userDiets) {
    // Приоритет: Carnivore > Keto > Standard
    if (hasCarnivore(userDiets)) {
      return 'carnivore';
    } else if (hasKeto(userDiets)) {
      return 'keto';
    } else {
      return null; // Стандартные диеты
    }
  }

  /// Расчет макросов для CARNIVORE диеты
  /// Алгоритм: 1% углеводов, 30-35% белки, 65-70% жиры на основе WHOOP данных
  MacrosBreakdown calcMacrosForCarnivore() {
    log(
      '[calcMacrosForCarnivore] Calculating carnivore macros',
      name: 'UserDataEntity',
    );
    log(
      '[calcMacrosForCarnivore] userWeightLbs: $userWeightLbs, calorieGoal: $calorieGoal, strain: $strainValue, recovery: $recoveryScore',
      name: 'UserDataEntity',
    );

    // Проверка на нулевой вес
    if (userWeightLbs <= 0) {
      log(
        'WARNING: userWeightLbs is zero or negative: $userWeightLbs',
        name: 'UserDataEntity',
      );

      // Используем среднее карнивор распределение для fallback
      final carnivoreCarbs = (0.01 * calorieGoal / 4).round(); // 1% углеводов
      final carnivoreProtein =
          (0.325 * calorieGoal / 4).round(); // 32.5% белков (среднее)
      final carnivoreFat =
          (0.665 * calorieGoal / 9).round(); // 66.5% жиров (среднее)

      log(
        '[calcMacrosForCarnivore] Using fallback carnivore distribution: P=$carnivoreProtein, C=$carnivoreCarbs, F=$carnivoreFat',
        name: 'UserDataEntity',
      );

      return MacrosBreakdown(
        kcal: calorieGoal,
        protein: carnivoreProtein,
        carbs: carnivoreCarbs,
        fat: carnivoreFat,
      );
    }

    // Углеводы всегда 1% для карнивор диеты
    const carbsPercent = 1.0;
    final carbsKcal = calorieGoal * (carbsPercent / 100);
    final carbs = (carbsKcal / 4).round(); // 4 ккал на грамм углеводов

    // Получаем проценты белков на основе WHOOP Strain
    final proteinPercentFromStrain = _getProteinPercentFromStrain(strainValue);

    // Получаем проценты белков на основе WHOOP Recovery
    final proteinPercentFromRecovery =
        _getProteinPercentFromRecovery(recoveryScore);

    // Комбинируем: 50% от strain + 50% от recovery (согласно ТЗ)
    final proteinPercent =
        (0.5 * proteinPercentFromStrain) + (0.5 * proteinPercentFromRecovery);

    // Жиры - оставшиеся проценты
    final fatPercent = 100.0 - carbsPercent - proteinPercent;

    log(
      '[calcMacrosForCarnivore] Strain-based protein: $proteinPercentFromStrain%, Recovery-based protein: $proteinPercentFromRecovery%',
      name: 'UserDataEntity',
    );
    log(
      '[calcMacrosForCarnivore] Final percentages - P: $proteinPercent%, C: $carbsPercent%, F: $fatPercent%',
      name: 'UserDataEntity',
    );

    // Рассчитываем граммы макросов
    final proteinKcal = calorieGoal * (proteinPercent / 100);
    final fatKcal = calorieGoal * (fatPercent / 100);

    final protein = (proteinKcal / 4).round(); // 4 ккал на грамм белка
    final fat = (fatKcal / 9).round(); // 9 ккал на грамм жира

    // Проверка на валидность
    final validProtein =
        protein > 0 ? protein : (0.325 * calorieGoal / 4).round();
    final validCarbs = carbs > 0 ? carbs : (0.01 * calorieGoal / 4).round();
    final validFat = fat > 0 ? fat : (0.665 * calorieGoal / 9).round();

    log(
      '[calcMacrosForCarnivore] Final carnivore macros - P: $validProtein г, C: $validCarbs г, F: $validFat г',
      name: 'UserDataEntity',
    );

    // Проверяем общие калории для отладки
    final totalKcal = (validProtein * 4) + (validCarbs * 4) + (validFat * 9);
    log(
      '[calcMacrosForCarnivore] Total calculated kcal: $totalKcal (target: $calorieGoal)',
      name: 'UserDataEntity',
    );

    return MacrosBreakdown(
      kcal: calorieGoal,
      protein: validProtein,
      carbs: validCarbs,
      fat: validFat,
    );
  }

  /// Получает проценты белков на основе WHOOP Strain для CARNIVORE диеты
  double _getProteinPercentFromStrain(double strain) {
    // Таблица соответствия Strain → Protein% для Carnivore (из ТЗ)
    if (strain >= 0 && strain <= 5) {
      return 30;
    } else if (strain >= 6 && strain <= 9) {
      return 31;
    } else if (strain >= 10 && strain <= 13) {
      return 32;
    } else if (strain >= 14 && strain <= 16) {
      return 33;
    } else if (strain >= 17 && strain <= 18) {
      return 34;
    } else if (strain >= 19) {
      return 35;
    } else {
      // Fallback для некорректных значений
      return 32.5; // Среднее значение
    }
  }

  /// Получает проценты белков на основе WHOOP Recovery для CARNIVORE диеты
  double _getProteinPercentFromRecovery(int recovery) {
    // Таблица соответствия Recovery → Protein% для Carnivore (из ТЗ)
    if (recovery >= 0 && recovery <= 19) {
      return 35;
    } else if (recovery >= 20 && recovery <= 39) {
      return 34;
    } else if (recovery >= 40 && recovery <= 59) {
      return 33;
    } else if (recovery >= 60 && recovery <= 79) {
      return 32;
    } else if (recovery >= 80 && recovery <= 89) {
      return 31;
    } else if (recovery >= 90 && recovery <= 100) {
      return 30;
    } else {
      // Fallback для некорректных значений
      return 32.5; // Среднее значение
    }
  }

  /// Расчет макросов для KETO диеты
  /// Алгоритм: 5-10% углеводов, 20-25% белки, 65-75% жиры на основе WHOOP данных
  MacrosBreakdown calcMacrosForKeto() {
    log(
      '[calcMacrosForKeto] Calculating keto macros',
      name: 'UserDataEntity',
    );
    log(
      '[calcMacrosForKeto] userWeightLbs: $userWeightLbs, calorieGoal: $calorieGoal, strain: $strainValue, recovery: $recoveryScore',
      name: 'UserDataEntity',
    );

    // Проверка на нулевой вес
    if (userWeightLbs <= 0) {
      log(
        'WARNING: userWeightLbs is zero or negative: $userWeightLbs',
        name: 'UserDataEntity',
      );

      // Используем среднее кето распределение для fallback
      final ketoProtein =
          (0.225 * calorieGoal / 4).round(); // 22.5% белков (среднее)
      final ketoCarbs =
          (0.075 * calorieGoal / 4).round(); // 7.5% углеводов (среднее)
      final ketoFat = (0.7 * calorieGoal / 9).round(); // 70% жиров (среднее)

      log(
        '[calcMacrosForKeto] Using fallback keto distribution: P=$ketoProtein, C=$ketoCarbs, F=$ketoFat',
        name: 'UserDataEntity',
      );

      return MacrosBreakdown(
        kcal: calorieGoal,
        protein: ketoProtein,
        carbs: ketoCarbs,
        fat: ketoFat,
      );
    }

    // Получаем проценты белков и углеводов на основе WHOOP Strain
    final strainMacros = _getKetoMacrosFromStrain(strainValue);

    // Получаем проценты белков и углеводов на основе WHOOP Recovery
    final recoveryMacros = _getKetoMacrosFromRecovery(recoveryScore);

    // Комбинируем: 50% от strain + 50% от recovery (согласно ТЗ)
    final proteinPercent =
        (0.5 * strainMacros.protein) + (0.5 * recoveryMacros.protein);
    final carbsPercent =
        (0.5 * strainMacros.carbs) + (0.5 * recoveryMacros.carbs);

    // Жиры - оставшиеся проценты
    final fatPercent = 100.0 - proteinPercent - carbsPercent;

    log(
      '[calcMacrosForKeto] Strain-based: P=${strainMacros.protein}%, C=${strainMacros.carbs}%',
      name: 'UserDataEntity',
    );
    log(
      '[calcMacrosForKeto] Recovery-based: P=${recoveryMacros.protein}%, C=${recoveryMacros.carbs}%',
      name: 'UserDataEntity',
    );
    log(
      '[calcMacrosForKeto] Final percentages - P: $proteinPercent%, C: $carbsPercent%, F: $fatPercent%',
      name: 'UserDataEntity',
    );

    // Рассчитываем граммы макросов
    final proteinKcal = calorieGoal * (proteinPercent / 100);
    final carbsKcal = calorieGoal * (carbsPercent / 100);
    final fatKcal = calorieGoal * (fatPercent / 100);

    final protein = (proteinKcal / 4).round(); // 4 ккал на грамм белка
    final carbs = (carbsKcal / 4).round(); // 4 ккал на грамм углеводов
    final fat = (fatKcal / 9).round(); // 9 ккал на грамм жира

    // Проверка на валидность
    final validProtein =
        protein > 0 ? protein : (0.225 * calorieGoal / 4).round();
    final validCarbs = carbs > 0 ? carbs : (0.075 * calorieGoal / 4).round();
    final validFat = fat > 0 ? fat : (0.7 * calorieGoal / 9).round();

    log(
      '[calcMacrosForKeto] Final keto macros - P: $validProtein г, C: $validCarbs г, F: $validFat г',
      name: 'UserDataEntity',
    );

    // Проверяем общие калории для отладки
    final totalKcal = (validProtein * 4) + (validCarbs * 4) + (validFat * 9);
    log(
      '[calcMacrosForKeto] Total calculated kcal: $totalKcal (target: $calorieGoal)',
      name: 'UserDataEntity',
    );

    return MacrosBreakdown(
      kcal: calorieGoal,
      protein: validProtein,
      carbs: validCarbs,
      fat: validFat,
    );
  }

  /// Получает проценты макросов на основе WHOOP Strain для KETO диеты
  ({double protein, double carbs}) _getKetoMacrosFromStrain(double strain) {
    // Таблица соответствия Strain → Macros% для Keto (из ТЗ)
    if (strain >= 0 && strain <= 5) {
      return (protein: 20.0, carbs: 5.0);
    } else if (strain >= 6 && strain <= 9) {
      return (protein: 21.0, carbs: 6.0);
    } else if (strain >= 10 && strain <= 13) {
      return (protein: 22.0, carbs: 7.0);
    } else if (strain >= 14 && strain <= 16) {
      return (protein: 23.0, carbs: 8.0);
    } else if (strain >= 17 && strain <= 18) {
      return (protein: 24.0, carbs: 9.0);
    } else if (strain >= 19) {
      return (protein: 25.0, carbs: 10.0);
    } else {
      // Fallback для некорректных значений
      return (protein: 22.5, carbs: 7.5); // Среднее значение
    }
  }

  /// Получает проценты макросов на основе WHOOP Recovery для KETO диеты
  ({double protein, double carbs}) _getKetoMacrosFromRecovery(int recovery) {
    // Таблица соответствия Recovery → Macros% для Keto (из ТЗ)
    if (recovery >= 0 && recovery <= 19) {
      return (protein: 25.0, carbs: 10.0);
    } else if (recovery >= 20 && recovery <= 39) {
      return (protein: 24.0, carbs: 9.0);
    } else if (recovery >= 40 && recovery <= 59) {
      return (protein: 23.0, carbs: 8.0);
    } else if (recovery >= 60 && recovery <= 79) {
      return (protein: 22.0, carbs: 7.0);
    } else if (recovery >= 80 && recovery <= 89) {
      return (protein: 21.0, carbs: 6.0);
    } else if (recovery >= 90 && recovery <= 100) {
      return (protein: 20.0, carbs: 5.0);
    } else {
      // Fallback для некорректных значений
      return (protein: 22.5, carbs: 7.5); // Среднее значение
    }
  }

  @override
  String toString() {
    return 'UserDataEntity(workouts: $workouts, userWeightLbs: $userWeightLbs, gender: $gender, strainValue: $strainValue, recoveryScore: $recoveryScore, sleepPerformance: $sleepPerformance, calorieGoal: $calorieGoal, askTime: $askTime)';
  }

  UserDataEntity copyWith({
    List<WorkoutModel>? workouts,
    double? userWeightLbs,
    Gender? gender,
    double? strainValue,
    int? recoveryScore,
    int? sleepPerformance,
    int? calorieGoal,
    DateTime? askTime,
    String? userId,
    int? currentCycleId,
  }) {
    return UserDataEntity(
      workouts: workouts ?? this.workouts,
      userWeightLbs: userWeightLbs ?? this.userWeightLbs,
      gender: gender ?? this.gender,
      strainValue: strainValue ?? this.strainValue,
      recoveryScore: recoveryScore ?? this.recoveryScore,
      sleepPerformance: sleepPerformance ?? this.sleepPerformance,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      askTime: askTime ?? this.askTime,
      userId: userId ?? this.userId,
      currentCycleId: currentCycleId ?? this.currentCycleId,
    );
  }
}
