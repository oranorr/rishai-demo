part of 'week_plan_bloc.dart';

@freezed
class WeekPlanState with _$WeekPlanState {
  const factory WeekPlanState({
    required List<WeekPlanEntity> allWeekPlans,
    required List<WeekPlanEntity> displayWeekPlans,
    WeekFilterEntity? filter,
    @Default(false) bool isLoading,
    String? error,
  }) = _WeekPlanState;
}
