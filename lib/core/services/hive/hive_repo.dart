part of 'hive_impl.dart';

abstract class HiveRepo {
  Future<void> initHive();
  Future<void> saveUser({required UserEntity user});
  Future<UserEntity?> retrieveSavedUser();
  Future<void> clear();

  Future<void> saveChatSnapshot({required ChatSnapshotEntity snapshot});
  Future<ChatSnapshotEntity?> retrieveLastChat();

  Future<void> saveDay({required DayEntity data});
  Future<List<DayEntity>> retrieveSavedDays();
  Future<void> flushSavedDays();
  Box get chatBox;

  Future<void> saveUserData({required UserDataEntity dataEntity});
  Future<UserDataEntity?> fetchUserDataEntity({required String userId});

  Future<void> disconnectWhoop();

  Future<void> refreshChat();
}
