import 'dart:convert';
import 'package:hive/hive.dart';

part 'user_goal_entity.g.dart';

@HiveType(typeId: 10)
class UserGoal {
  UserGoal({
    required this.goal,
    required this.modificator,
    required this.updatedAt,
  });

  factory UserGoal.fromMap(Map<String, dynamic> map) {
    return UserGoal(
      goal: GoalType.values.byName((map['goalType'] ?? 'optimize') as String),
      modificator: _parseModificator(map['modificator']),
      updatedAt: _parseUpdatedAt(map['updatedAt']),
    );
  }

  /// Парсит modificator из разных форматов бекенда: int, double, или string (например "-0.01")
  static double _parseModificator(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Парсит updatedAt из int (milliseconds) или string (ISO 8601, например "2026-03-18T14:56:03.047")
  static DateTime _parseUpdatedAt(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  factory UserGoal.fromJson(String source) =>
      UserGoal.fromMap(json.decode(source) as Map<String, dynamic>);
  @HiveField(0)
  final GoalType goal;
  @HiveField(1)
  final double modificator;
  @HiveField(2)
  final DateTime updatedAt;

  UserGoal copyWith({
    GoalType? goal,
    double? modificator,
    DateTime? updatedAt,
  }) {
    return UserGoal(
      goal: goal ?? this.goal,
      modificator: modificator ?? this.modificator,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'UserGoal(goal: $goal, modificator: $modificator, updatedAt: $updatedAt)';

  List<double> getModificators() {
    switch (goal) {
      // В плане Aesthetics - дефицит от -1 до - 20% с шагом в 1 процент
      case GoalType.aesthetics:
        // return
        return [
          -0.01,
          -0.02,
          -0.03,
          -0.04,
          -0.05,
          -0.06,
          -0.07,
          -0.08,
          -0.09,
          -0.1,
          -0.11,
          -0.12,
          -0.13,
          -0.14,
          -0.15,
          -0.16,
          -0.17,
          -0.18,
          -0.19,
          -0.2,
        ];
      case GoalType.recomp:
        return [-0.05, 0.05];
      // В плане Performance - профицит от +1 до +15% с шагом в 1 процент
      case GoalType.performance:
        return [
          0.01,
          0.02,
          0.03,
          0.04,
          0.05,
          0.06,
          0.07,
          0.08,
          0.09,
          0.1,
          0.11,
          0.12,
          0.13,
          0.14,
          0.15,
        ];
      case GoalType.optimize:
        return [0.0];
    }
  }

  String getSettingsDescription() {
    switch (goal) {
      case GoalType.aesthetics:
        return 'This variable can only be changed once per day, before meal plan generation.';
      case GoalType.recomp:
        return 'This variable cannot be changed manually. It automatically changes every two weeks.';
      case GoalType.performance:
        return 'This variable can only be changed once per day, before meal plan generation.';
      case GoalType.optimize:
        return 'This variable stays unchanged for this setting.';
    }
  }

  String getGoalTypeName() {
    switch (goal) {
      case GoalType.aesthetics:
        return 'Fat Loss';
      case GoalType.performance:
        return 'Muscle Gain';
      case GoalType.recomp:
        return 'Body Recomp';
      case GoalType.optimize:
        return 'Optimize Me';
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'goal': goal.name,
      'modificator': modificator,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserGoal &&
        other.goal == goal &&
        other.modificator == modificator &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => goal.hashCode ^ modificator.hashCode ^ updatedAt.hashCode;
}

@HiveType(typeId: 11)
enum GoalType {
  @HiveField(0)
  aesthetics,
  @HiveField(1)
  performance,
  @HiveField(2)
  recomp,
  @HiveField(3)
  optimize
}
