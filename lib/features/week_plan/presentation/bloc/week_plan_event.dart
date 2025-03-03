part of 'week_plan_bloc.dart';

@freezed
class WeekPlanEvent with _$WeekPlanEvent {
  const factory WeekPlanEvent.generate({
    required List<String> dietary,
    required List<String> cuisines,
    required List<String> restrictions,
    required int calorieTarget,
    required MacrosBreakdown macros,
    required bool hasTraining,
    required bool hasSnack,
    required List<ServingEntity> servings,
  }) = WeekPlanGenerate;

  const factory WeekPlanEvent.reset() = WeekPlanReset;

  const factory WeekPlanEvent.load() = WeekPlanLoad;

  const factory WeekPlanEvent.clear() = WeekPlanClear;
}
