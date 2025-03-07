part of 'remote_data_source_impl.dart';

abstract class WhoopRemoteDataSource {
  Future<BodyMeasurementsEntity?> getBodyData();
  Future<(List<CycleModel>, int)> getCycles();
  Future<List<WorkoutModel>> getWorkoutsOfCycle({required CycleModel cycle});
  Future<RecoveryModel?> getRecoveryOfCycle({required int cycleId});
  Future<SleepModel?> getLastSleep();
  Future<void> updateDirectus({required DayEntity day});
  Future<DayEntity?> fetchDirectusData();
  // Future<bool> pingCurrentCycle();
  Future<bool> pingLastCycle({required int? cycleId});
  Future<bool> clearWhoopUserDataOnDisconnect({required String userId});
  Future<bool> doesChatNeedsRefreshment({required String userId});
  // Future<Map<String, dynamic>?> getCycleById({required int cycleId});
  Future<List<DayEntity>> getDaysWithMealPlans({required List<int> daysIds});
}
