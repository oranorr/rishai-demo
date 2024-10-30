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
}
