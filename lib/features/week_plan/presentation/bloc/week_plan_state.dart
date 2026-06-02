part of 'week_plan_bloc.dart';

@freezed
class WeekPlanState with _$WeekPlanState {
  const factory WeekPlanState({
    required List<WeekPlanEntity> allWeekPlans,
    required List<WeekPlanEntity> displayWeekPlans,
    WeekFilterEntity? filter,
    @Default(false) bool isLoading,

    /// Идёт фоновая синхронизация preps с backend (revalidate-фаза SWR).
    /// Используем для деликатного индикатора, НЕ перекрывая уже готовый список.
    @Default(false) bool isSyncing,

    /// Был ли хотя бы один завершённый цикл загрузки (кэш или сеть).
    /// Пока false и список пуст — показываем skeleton, а не «нет планов»,
    /// чтобы убрать вспышку «There are no preps yet» на первом входе.
    @Default(false) bool hasLoaded,
    String? error,
  }) = _WeekPlanState;
}
