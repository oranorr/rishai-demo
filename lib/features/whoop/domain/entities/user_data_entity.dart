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

  /// Расчет макросов для кето/карнивор диеты
  /// Алгоритм: 10% углеводов, остальные калории поровну между белками и жирами
  MacrosBreakdown calcMacrosForKetoCarnivore() {
    log('[calcMacrosForKetoCarnivore] Calculating keto/carnivore macros',
        name: 'UserDataEntity');
    log('[calcMacrosForKetoCarnivore] userWeightLbs: $userWeightLbs, calorieGoal: $calorieGoal',
        name: 'UserDataEntity');

    // Проверка на нулевой вес
    if (userWeightLbs <= 0) {
      log('WARNING: userWeightLbs is zero or negative: $userWeightLbs',
          name: 'UserDataEntity');

      // Используем кето/карнивор распределение даже для стандартных значений
      final ketoCarbs =
          (0.1 * calorieGoal / 4).round(); // 10% калорий от углеводов
      final remainingKcal = calorieGoal - (ketoCarbs * 4); // Оставшиеся калории
      final ketoProtein =
          (0.5 * remainingKcal / 4).round(); // 50% оставшихся калорий от белка
      final ketoFat =
          (0.5 * remainingKcal / 9).round(); // 50% оставшихся калорий от жиров

      log('[calcMacrosForKetoCarnivore] Using standard keto distribution: P=$ketoProtein, C=$ketoCarbs, F=$ketoFat',
          name: 'UserDataEntity');

      return MacrosBreakdown(
        kcal: calorieGoal,
        protein: ketoProtein,
        carbs: ketoCarbs,
        fat: ketoFat,
      );
    }

    // Сначала рассчитываем стандартные макросы
    final standardProtein = calcProteins();
    final standardFats = clacFats();
    final standardCarbs = calcCarbs(
      kalorieGoal: calorieGoal,
      proteinsInKcal: standardProtein * 4,
      fatsInKcal: standardFats * 9,
    );

    log('[calcMacrosForKetoCarnivore] Standard macros - P: $standardProtein, C: $standardCarbs, F: $standardFats',
        name: 'UserDataEntity');

    // Применяем кето/карнивор алгоритм
    // 1. Ограничиваем углеводы до 10% от общих калорий
    final newCarbsKcal = calorieGoal * 0.10; // 10% от общих калорий
    final newCarbs =
        (newCarbsKcal / 4).round(); // Конвертируем в граммы (4 ккал/г)

    // 2. Вычисляем освободившиеся калории
    final standardCarbsKcal = standardCarbs * 4;
    final freedKcal = standardCarbsKcal - newCarbsKcal;

    log('[calcMacrosForKetoCarnivore] Carbs reduction: ${standardCarbsKcal}kcal -> ${newCarbsKcal}kcal (freed: ${freedKcal}kcal)',
        name: 'UserDataEntity');

    // 3. Распределяем освободившиеся калории поровну между белками и жирами
    final additionalProteinKcal = freedKcal / 2;
    final additionalFatKcal = freedKcal / 2;

    final newProtein =
        standardProtein + (additionalProteinKcal / 4).round(); // 4 ккал/г
    final newFats = standardFats + (additionalFatKcal / 9).round(); // 9 ккал/г

    // Проверка на нулевые значения и исправление
    final validProtein = newProtein > 0
        ? newProtein
        : (0.45 * calorieGoal / 4).round(); // 45% если что-то пошло не так
    final validCarbs = newCarbs > 0
        ? newCarbs
        : (0.1 * calorieGoal / 4).round(); // 10% если что-то пошло не так
    final validFat = newFats > 0
        ? newFats
        : (0.45 * calorieGoal / 9).round(); // 45% если что-то пошло не так

    log('[calcMacrosForKetoCarnivore] Final keto/carnivore macros - P: $validProtein, C: $validCarbs, F: $validFat',
        name: 'UserDataEntity');

    // Проверяем общие калории для отладки
    final totalKcal = (validProtein * 4) + (validCarbs * 4) + (validFat * 9);
    log('[calcMacrosForKetoCarnivore] Total calculated kcal: $totalKcal (target: $calorieGoal)',
        name: 'UserDataEntity');

    return MacrosBreakdown(
      kcal: calorieGoal, // Сохраняем целевые калории
      protein: validProtein,
      carbs: validCarbs,
      fat: validFat,
    );
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
