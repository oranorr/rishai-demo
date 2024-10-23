part of 'hive_impl.dart';

abstract class HiveRepo {
  Future<void> initHive();
  Future<void> saveUser({required UserEntity user});
  Future<UserEntity?> retrieveSavedUser();
  Future<void> clear();

  Future<void> saveChatSnapshot({required ChatSnapshotEntity snapshot});
  Future<ChatSnapshotEntity?> retrieveLastChat();

  Future<void> saveWhoopData({required WhoopDataEntity data});
  Future<WhoopDataEntity?> retrieveLastData();
  Box get chatBox;

  Future<void> saveUserData({required UserDataEntity dataEntity});
  Future<UserDataEntity?> fetchUserDataEntity({required String userId});
}
