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
    required DateTime startDate,
  }) = WeekPlanGenerate;

  const factory WeekPlanEvent.reset() = WeekPlanReset;

  /// [weekPlanIdHint] — свежий список id из GET /users/:id, чтобы не гоняться
  /// за устаревшим [userBloc.state] при fallback readOne (см. userId 462 != 8).
  const factory WeekPlanEvent.load({List<int>? weekPlanIdHint}) = WeekPlanLoad;

  const factory WeekPlanEvent.clear() = WeekPlanClear;

  const factory WeekPlanEvent.filter({
    required WeekFilterEntity filter,
  }) = WeekPlanFilter;

  const factory WeekPlanEvent.clearFilter() = WeekPlanClearFilter;
}
