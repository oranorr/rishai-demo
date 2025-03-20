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
  Future<List<DayEntity>> retrieveSavedDays();
  Future<void> flushSavedDays();
  Box get chatBox;

  Future<void> saveUserData({required UserDataEntity dataEntity});
  Future<UserDataEntity?> fetchUserDataEntity({required String userId});

  Future<void> disconnectWhoop();

  Future<void> refreshChat();

  Future<void> saveWeekPlan({required WeekPlanEntity weekPlan});
  Future<List<WeekPlanEntity>?> retrieveWeekPlan();

  Future<void> clearWeekPlans();

  void test();
}
