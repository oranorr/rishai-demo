import 'package:equatable/equatable.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';

/// Параметры для генерации недельного плана (как на клиенте, так и для
/// `POST /tasks/enqueue` с типом `weekly_meal_plan`).
class WeekPlanParams extends Equatable {
  const WeekPlanParams({
    required this.dietary,
    required this.cuisines,
    required this.restrictions,
    required this.calorieTarget,
    required this.macros,
    required this.hasTraining,
    required this.hasSnack,
    required this.servings,
    required this.startDate,
  });
  final List<String> dietary;
  final List<String> cuisines;
  final List<String> restrictions;
  final int calorieTarget;
  final MacrosBreakdown macros;
  final bool hasTraining;
  final bool hasSnack;
  final List<ServingEntity> servings;
  final DateTime startDate;

  @override
  List<Object?> get props => [
        dietary,
        cuisines,
        restrictions,
        calorieTarget,
        macros,
        hasTraining,
        hasSnack,
        servings,
        startDate,
      ];
}
