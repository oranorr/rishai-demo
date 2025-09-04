// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';

part 'week_plan_entity.g.dart';

@HiveType(typeId: 17)
class WeekPlanEntity extends Equatable {
  const WeekPlanEntity({
    required this.userId,
    required this.plans,
    required this.startDate,
    required this.endDate,
    required this.fitnessGoal,
    required this.dietaryPreferences,
    required this.cuisines,
    required this.mealsTypes,
  });

  factory WeekPlanEntity.create({
    required String userId,
    required List<MealPlanEntity> plans,
    required DateTime startDate,
  }) {
    // final tomorrow = DateTime.now().add(const Duration(days: 1));

    final endDate =
        startDate.add(const Duration(days: 4)); // +4 так как включая завтра

    return WeekPlanEntity(
      userId: userId,
      plans: plans,
      startDate: startDate,
      endDate: endDate,
      fitnessGoal: '',
      dietaryPreferences: '',
      cuisines: const [],
      mealsTypes: const [],
    );
  }

  factory WeekPlanEntity.fromMap(Map<String, dynamic> map) {
    return WeekPlanEntity(
      userId: map['userId'].toString(),
      plans: List<MealPlanEntity>.from(
        (map['mealPlans'] as List).map(
          (plan) => MealPlanEntity.fromMap(plan as Map<String, dynamic>),
        ),
      ),
      startDate: DateTime.fromMillisecondsSinceEpoch(
        int.parse(map['startDate'] as String),
      ),
      endDate: DateTime.fromMillisecondsSinceEpoch(
        int.parse(map['endDate'] as String),
      ),
      fitnessGoal: map['fitnessGoal'] ?? '',
      dietaryPreferences: map['dietaryPreferences'] ?? '',
      cuisines: List<String>.from(map['cuisines'] ?? []),
      mealsTypes: List<String>.from(map['mealsTypes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mealPlans': plans.map((plan) => plan.toMap()).toList(),
      'startDate': startDate.millisecondsSinceEpoch.toString(),
      'endDate': endDate.millisecondsSinceEpoch.toString(),
      'fitnessGoal': fitnessGoal,
      'dietaryPreferences': dietaryPreferences,
      'cuisines': cuisines,
      'mealsTypes': mealsTypes,
    };
  }

  String formatPeriod() {
    final yearFormat = DateFormat('yyyy');
    final monthFormat = DateFormat('MMM');
    final dayFormat = DateFormat('d');

    final year = yearFormat.format(startDate);
    final month = monthFormat.format(startDate);
    final startDay = dayFormat.format(startDate);
    final endDay = dayFormat.format(endDate);

    return '$year $month $startDay-$endDay';
  }

  @HiveField(0)
  final String userId;
  @HiveField(1)
  final List<MealPlanEntity> plans;
  @HiveField(2)
  final DateTime startDate;
  @HiveField(3)
  final DateTime endDate;
  @HiveField(4)
  final String fitnessGoal;
  @HiveField(5)
  final String dietaryPreferences;
  @HiveField(6)
  final List<String> cuisines;
  @HiveField(7)
  final List<String> mealsTypes;

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  @override
  List<Object?> get props => [userId, plans, startDate, endDate];

  WeekPlanEntity copyWith({
    String? userId,
    List<MealPlanEntity>? plans,
    DateTime? startDate,
    DateTime? endDate,
    String? fitnessGoal,
    String? dietaryPreferences,
    List<String>? cuisines,
    List<String>? mealsTypes,
  }) {
    return WeekPlanEntity(
      userId: userId ?? this.userId,
      plans: plans ?? this.plans,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      cuisines: cuisines ?? this.cuisines,
      mealsTypes: mealsTypes ?? this.mealsTypes,
    );
  }
}
