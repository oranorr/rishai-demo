part of 'remote_data_source_impl.dart';

abstract class WhoopRemoteDataSource {
  Future<bool> isWhoopConnected();
  Future<DayEntity> getCurrentDay({bool forceRefresh = false});
  Future<BodyMeasurementsEntity?> getBodyData();
  Future<bool> pingLastCycle({required int? cycleId});
  Future<bool> clearWhoopUserDataOnDisconnect({required String userId});
}
