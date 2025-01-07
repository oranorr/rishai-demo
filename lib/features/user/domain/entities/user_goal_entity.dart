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
      goal: GoalType.values.byName(map['goal']),
      modificator: map['modificator'].runtimeType == int
          ? map['modificator'].toDouble()
          : map['modificator'] as double,
      updatedAt: DateTime.fromMicrosecondsSinceEpoch(map['updatedAt']),
    );
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
        return 'Calorie modificator of this type could be changed only once per day, and only before meal plan was created.';
      case GoalType.recomp:
        return 'Modificator of this goal type cannot be changed manually. It changes automatically every two weeks.';
      case GoalType.performance:
        return 'Calorie modificator of this type could be changed only once per day, and only before meal plan was created.';
      case GoalType.optimize:
        return 'The % stays unchanged for this setting';
    }
  }

  String getGoalTypeName() {
    switch (goal) {
      case GoalType.aesthetics:
        return 'Aesthetics';
      case GoalType.performance:
        return 'Performance';
      case GoalType.recomp:
        return 'Recomp';
      case GoalType.optimize:
        return 'Optimize me';
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
