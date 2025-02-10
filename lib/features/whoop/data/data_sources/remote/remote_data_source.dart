part of 'remote_data_source_impl.dart';

abstract class WhoopRemoteDataSource {
  Future<BodyMeasurementsEntity?> getBodyData();
  Future<(List<CycleModel>, int)> getCycles();
  Future<List<WorkoutModel>> getWorkoutsOfCycle({required CycleModel cycle});
  Future<RecoveryModel?> getRecoveryOfCycle({required int cycleId});
  Future<SleepModel?> getLastSleep();
  Future<void> updateDirectus({required WhoopDataEntity data});
  Future<WhoopDataEntity?> fetchDirectusData();
  Future<bool> pingCurrentCycle({required int cycleId});
  Future<bool> clearWhoopUserDataOnDisconnect({required String userId});
  Future<bool> doesChatNeedsRefreshment({required String userId});
  // Future<Map<String, dynamic>?> getCycleById({required int cycleId});
}
