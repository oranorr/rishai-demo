part of 'week_plan_bloc.dart';

@freezed
class WeekPlanState with _$WeekPlanState {
  const factory WeekPlanState({
    required List<WeekPlanEntity?> weekPlans,
    @Default(false) bool isLoading,
    String? error,
  }) = _WeekPlanState;
}
