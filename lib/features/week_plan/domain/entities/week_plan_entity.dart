import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';

part 'week_plan_entity.g.dart';

@HiveType(typeId: 17)
class WeekPlanEntity extends Equatable {
  const WeekPlanEntity({
    required this.plans,
    required this.startDate,
    required this.endDate,
  });

  factory WeekPlanEntity.create({
    required List<MealPlanEntity> plans,
    required DateTime startDate,
  }) {
    // final tomorrow = DateTime.now().add(const Duration(days: 1));

    final endDate =
        startDate.add(const Duration(days: 4)); // +4 так как включая завтра

    return WeekPlanEntity(
      plans: plans,
      startDate: startDate,
      endDate: endDate,
    );
  }

  factory WeekPlanEntity.fromMap(Map<String, dynamic> map) {
    return WeekPlanEntity(
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
    );
  }

  Map<String, dynamic> toMap({required String userId}) {
    return {
      'mealPlans': plans.map((plan) => plan.toMap()).toList(),
      'startDate': startDate.millisecondsSinceEpoch.toString(),
      'endDate': endDate.millisecondsSinceEpoch.toString(),
      'userId': userId,
    };
  }

  @HiveField(0)
  final List<MealPlanEntity> plans;

  @HiveField(1)
  final DateTime startDate;

  @HiveField(2)
  final DateTime endDate;

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  @override
  List<Object?> get props => [plans, startDate, endDate];
}
