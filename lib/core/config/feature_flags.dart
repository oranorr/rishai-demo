/// Централизованные фиче-флаги приложения.
///
/// Для миграции дневного плана питания на async tasks (backend).
/// В дальнейшем можно перевести на `appConfig`/RemoteConfig.
const bool kUseAsyncDailyMealPlan = true;

/// Недельный план: `POST /tasks/enqueue` (`weekly_meal_plan`) + поллинг вместо
/// 5× [RequestPlanUsecaseV2] на устройстве.
const bool kUseAsyncWeeklyMealPlan = true;
