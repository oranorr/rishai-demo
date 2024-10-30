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
        sleepPerformance: sleepPerformance);

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
                          activity: getActivity(workouts.first.sportId))
                      .protein) +
              (0.3 * calc.calcStrain().protein) +
              (0.1 * calc.calculateRecovery().protein) +
              (0.1 * calc.calculateSleepPerformance().protein)) *
          userWeightLbs;
      return proteins.round();
    } else if (workouts.length > 1) {
      for (WorkoutModel workout in workouts) {
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
        sleepPerformance: 0);

    final res = (((0.5 * calc.calcStrain().fats) +
            (0.5 * calc.calculateRecovery().fats)) *
        userWeightLbs);
    return res.round();
  }

  int calcCarbs(
      {required int kalorieGoal,
      required int proteinsInKcal,
      required int fatsInKcal}) {
    int carbsInCals = kalorieGoal - proteinsInKcal - fatsInKcal;
    double carbs = carbsInCals / 4;
    return carbs.round();
  }

  MacrosBreakdown calcMacros() {
    final protein = calcProteins();
    final fats = clacFats();
    final carbs = calcCarbs(
        kalorieGoal: calorieGoal,
        proteinsInKcal: protein * 4,
        fatsInKcal: fats * 9);

    return MacrosBreakdown(
      kcal: calorieGoal,
      protein: protein,
      carbs: carbs,
      fat: clacFats(),
    );
  }

  @override
  String toString() {
    return 'UserDataEntity(workouts: $workouts, userWeightLbs: $userWeightLbs, gender: $gender, strainValue: $strainValue, recoveryScore: $recoveryScore, sleepPerformance: $sleepPerformance, calorieGoal: $calorieGoal, askTime: $askTime)';
  }

  UserDataEntity copyWith(
      {List<WorkoutModel>? workouts,
      double? userWeightLbs,
      Gender? gender,
      double? strainValue,
      int? recoveryScore,
      int? sleepPerformance,
      int? calorieGoal,
      DateTime? askTime,
      String? userId,
      int? currentCycleId}) {
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
        currentCycleId: currentCycleId ?? this.currentCycleId);
  }
}
