part of 'hive_impl.dart';

abstract class HiveRepo {
  Future<void> initHive();
  Future<void> saveUser({required UserEntity user});
  Future<UserEntity?> retrieveSavedUser();
  Future<void> clear();

  Future<void> saveChatSnapshot(ChatSnapshotEntity snapshot, [DateTime? date]);
  Future<void> clearMealPlan();
  Future<ChatSnapshotEntity?> getChatSnapshot([DateTime? date]);
  Future<ChatSnapshotEntity?> retrieveLastChat();

  Future<void> saveDay({required DayEntity data});

  /// Атомарно заменяет весь кэш дней (clear + batch add).
  /// Используется после full sync, чтобы убрать дубликаты Hive.
  Future<void> replaceSavedDays({required List<DayEntity> days});

  Future<List<DayEntity>> retrieveSavedDays();
  Future<void> flushSavedDays();

  /// Кэш недельных планов (preps) для stale-while-revalidate.
  /// Атомарно заменяет весь кэш списком с backend.
  Future<void> replaceSavedWeekPlans({required List<WeekPlanEntity> weeks});
  Future<List<WeekPlanEntity>> retrieveSavedWeekPlans();
  Future<void> flushWeekPlans();
  Future<void> deleteLastDay();
  Box get chatBox;

  Future<void> saveUserData({required UserDataEntity dataEntity});
  Future<UserDataEntity?> fetchUserDataEntity({required String userId});
  Future<List<UserDataEntity>> retrieveAllUserData();

  Future<void> disconnectWhoop();

  Future<void> refreshChat();

  Future<void> resetStorageOnFatalError();

  void test();
}
