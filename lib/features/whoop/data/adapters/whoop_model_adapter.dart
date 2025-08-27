import 'package:rishai/features/whoop/data/models/sleep_model.dart';
import 'package:rishai/features/whoop/data/models/workout_model.dart';
import 'package:rishai/features/whoop/data/models/cycle_model.dart';
import 'package:rishai/features/whoop/data/models/recovery_model.dart';
import 'package:rishai/features/whoop/data/models/v2/sleep_model_v2.dart';
import 'package:rishai/features/whoop/data/models/v2/workout_model_v2.dart';
import 'package:rishai/features/whoop/data/models/v2/cycle_model_v2.dart';
import 'package:rishai/features/whoop/data/models/v2/recovery_model_v2.dart';

/// Адаптер для конвертации между v1 и v2 моделями WHOOP
/// Обеспечивает обратную совместимость при миграции с v1 на v2
class WhoopModelAdapter {
  // ===== SLEEP MODELS =====

  /// Конвертировать SleepModelV2 в старый SleepModel для обратной совместимости
  static SleepModel toV1SleepModel(SleepModelV2 v2Model) {
    return SleepModel(
      id: v2Model.idAsInt ??
          0, // Используем activityV1Id если доступен, иначе 0
      userId: v2Model.userId,
      createdAt: v2Model.createdAt,
      updatedAt: v2Model.updatedAt,
      start: v2Model.start,
      end: v2Model.end,
      nap: v2Model.nap,
      scoreState: v2Model.scoreState,
      score: v2Model.score != null
          ? _convertSleepScoreV2ToV1(v2Model.score!)
          : null,
    );
  }

  /// Конвертировать SleepModel в SleepModelV2
  static SleepModelV2 toV2SleepModel(SleepModel v1Model) {
    return SleepModelV2(
      id: v1Model.id, // int ID
      userId: v1Model.userId,
      createdAt: v1Model.createdAt,
      updatedAt: v1Model.updatedAt,
      start: v1Model.start,
      end: v1Model.end,
      nap: v1Model.nap,
      scoreState: v1Model.scoreState,
      score: v1Model.score != null
          ? _convertSleepScoreV1ToV2(v1Model.score!)
          : null,
      activityV1Id: v1Model.id, // Сохраняем оригинальный v1 ID
    );
  }

  // ===== WORKOUT MODELS =====

  /// Конвертировать WorkoutModelV2 в старый WorkoutModel
  static WorkoutModel toV1WorkoutModel(WorkoutModelV2 v2Model) {
    return WorkoutModel(
      id: v2Model.idAsInt ?? 0,
      userId: v2Model.userId,
      createdAt: v2Model.createdAt,
      updatedAt: v2Model.updatedAt,
      start: v2Model.start,
      end: v2Model.end,
      timezoneOffset: v2Model.timezoneOffset,
      sportId: v2Model.sportId,
      scoreState: v2Model.scoreState,
      score: v2Model.score != null
          ? _convertWorkoutScoreV2ToV1(v2Model.score!)
          : null,
    );
  }

  /// Конвертировать WorkoutModel в WorkoutModelV2
  static WorkoutModelV2 toV2WorkoutModel(WorkoutModel v1Model) {
    return WorkoutModelV2(
      id: v1Model.id, // int ID
      userId: v1Model.userId,
      createdAt: v1Model.createdAt,
      updatedAt: v1Model.updatedAt,
      start: v1Model.start,
      end: v1Model.end,
      timezoneOffset: v1Model.timezoneOffset,
      sportId: v1Model.sportId,
      scoreState: v1Model.scoreState,
      score: v1Model.score != null
          ? _convertWorkoutScoreV1ToV2(v1Model.score!)
          : null,
      activityV1Id: v1Model.id, // Сохраняем оригинальный v1 ID
    );
  }

  // ===== CYCLE MODELS =====

  /// Конвертировать CycleModelV2 в старый CycleModel
  static CycleModel toV1CycleModel(CycleModelV2 v2Model) {
    return CycleModel(
      id: v2Model.idAsInt ?? 0,
      userId: v2Model.userId,
      createdAt: v2Model.createdAt,
      updatedAt: v2Model.updatedAt,
      start: v2Model.start,
      end: v2Model.end,
      scoreState: v2Model.scoreState,
      score: v2Model.score != null
          ? _convertCycleScoreV2ToV1(v2Model.score!)
          : null,
    );
  }

  /// Конвертировать CycleModel в CycleModelV2
  static CycleModelV2 toV2CycleModel(CycleModel v1Model) {
    return CycleModelV2(
      id: v1Model.id, // int ID
      userId: v1Model.userId,
      createdAt: v1Model.createdAt,
      updatedAt: v1Model.updatedAt,
      start: v1Model.start,
      end: v1Model.end,
      scoreState: v1Model.scoreState,
      score: v1Model.score != null
          ? _convertCycleScoreV1ToV2(v1Model.score!)
          : null,
      activityV1Id: v1Model.id, // Сохраняем оригинальный v1 ID
    );
  }

  // ===== RECOVERY MODELS =====

  /// Конвертировать RecoveryModelV2 в старый RecoveryModel
  static RecoveryModel toV1RecoveryModel(RecoveryModelV2 v2Model) {
    return RecoveryModel(
      cycleId: v2Model.cycleIdAsInt ?? 0,
      sleepId: v2Model.sleepIdAsInt ?? 0,
      userId: v2Model.userId,
      createdAt: v2Model.createdAt,
      updatedAt: v2Model.updatedAt,
      scoreState: v2Model.scoreState,
      score: v2Model.score != null
          ? _convertRecoveryScoreV2ToV1(v2Model.score!)
          : null,
    );
  }

  /// Конвертировать RecoveryModel в RecoveryModelV2
  static RecoveryModelV2 toV2RecoveryModel(RecoveryModel v1Model) {
    return RecoveryModelV2(
      cycleId: v1Model.cycleId, // int ID
      sleepId: v1Model.sleepId, // int ID
      userId: v1Model.userId,
      createdAt: v1Model.createdAt,
      updatedAt: v1Model.updatedAt,
      scoreState: v1Model.scoreState,
      score: v1Model.score != null
          ? _convertRecoveryScoreV1ToV2(v1Model.score!)
          : null,
      activityV1Id: v1Model.cycleId, // Сохраняем оригинальный v1 cycle ID
    );
  }

  // ===== PRIVATE HELPER METHODS =====

  /// Конвертировать SleepScoreModelV2 в SleepScoreModel
  static SleepScoreModel _convertSleepScoreV2ToV1(SleepScoreModelV2 v2Score) {
    return SleepScoreModel(
      stageSummary: v2Score.stageSummary != null
          ? _convertStageSummaryV2ToV1(v2Score.stageSummary!)
          : null,
      sleepNeeded: v2Score.sleepNeeded != null
          ? _convertSleepNeededV2ToV1(v2Score.sleepNeeded!)
          : null,
      respiratoryRate: v2Score.respiratoryRate,
      sleepPerformancePercentage: v2Score.sleepPerformancePercentage,
      sleepConsistencyPercentage: v2Score.sleepConsistencyPercentage,
      sleepEfficiencyPercentage: v2Score.sleepEfficiencyPercentage,
    );
  }

  /// Конвертировать SleepScoreModel в SleepScoreModelV2
  static SleepScoreModelV2 _convertSleepScoreV1ToV2(SleepScoreModel v1Score) {
    return SleepScoreModelV2(
      stageSummary: v1Score.stageSummary != null
          ? _convertStageSummaryV1ToV2(v1Score.stageSummary!)
          : null,
      sleepNeeded: v1Score.sleepNeeded != null
          ? _convertSleepNeededV1ToV2(v1Score.sleepNeeded!)
          : null,
      respiratoryRate: v1Score.respiratoryRate,
      sleepPerformancePercentage: v1Score.sleepPerformancePercentage,
      sleepConsistencyPercentage: v1Score.sleepConsistencyPercentage,
      sleepEfficiencyPercentage: v1Score.sleepEfficiencyPercentage,
    );
  }

  /// Конвертировать WorkoutScoreV2 в WorkoutScore
  static WorkoutScore _convertWorkoutScoreV2ToV1(WorkoutScoreV2 v2Score) {
    return WorkoutScore(
      strain: v2Score.strain,
      averageHeartRate: v2Score.averageHeartRate,
      maxHeartRate: v2Score.maxHeartRate,
      kilojoule: v2Score.kilojoule,
      percentRecorded: v2Score.percentRecorded,
      distanceMeter: v2Score.distanceMeter,
    );
  }

  /// Конвертировать WorkoutScore в WorkoutScoreV2
  static WorkoutScoreV2 _convertWorkoutScoreV1ToV2(WorkoutScore v1Score) {
    return WorkoutScoreV2(
      strain: v1Score.strain,
      averageHeartRate: v1Score.averageHeartRate,
      maxHeartRate: v1Score.maxHeartRate,
      kilojoule: v1Score.kilojoule,
      percentRecorded: v1Score.percentRecorded,
      distanceMeter: v1Score.distanceMeter,
    );
  }

  /// Конвертировать CycleScoreV2 в CycleScore
  static CycleScore _convertCycleScoreV2ToV1(CycleScoreV2 v2Score) {
    return CycleScore(
      strain: v2Score.strain,
      kilojoule: v2Score.kilojoule,
      averageHeartRate: v2Score.averageHeartRate,
      maxHeartRate: v2Score.maxHeartRate,
    );
  }

  /// Конвертировать CycleScore в CycleScoreV2
  static CycleScoreV2 _convertCycleScoreV1ToV2(CycleScore v1Score) {
    return CycleScoreV2(
      strain: v1Score.strain,
      kilojoule: v1Score.kilojoule,
      averageHeartRate: v1Score.averageHeartRate,
      maxHeartRate: v1Score.maxHeartRate,
    );
  }

  /// Конвертировать RecoveryScoreModelV2 в RecoveryScoreModel
  static RecoveryScoreModel _convertRecoveryScoreV2ToV1(
      RecoveryScoreModelV2 v2Score) {
    return RecoveryScoreModel(
      userCalibrating: v2Score.userCalibrating,
      recoveryScore: v2Score.recoveryScore,
      restingHeartRate: v2Score.restingHeartRate,
      hrvRmssd: v2Score.hrvRmssd,
      spo2Percentage: v2Score.spo2Percentage,
      skinTemp: v2Score.skinTemp,
    );
  }

  /// Конвертировать RecoveryScoreModel в RecoveryScoreModelV2
  static RecoveryScoreModelV2 _convertRecoveryScoreV1ToV2(
      RecoveryScoreModel v1Score) {
    return RecoveryScoreModelV2(
      userCalibrating: v1Score.userCalibrating,
      recoveryScore: v1Score.recoveryScore,
      restingHeartRate: v1Score.restingHeartRate,
      hrvRmssd: v1Score.hrvRmssd,
      spo2Percentage: v1Score.spo2Percentage,
      skinTemp: v1Score.skinTemp,
    );
  }

  // ===== STAGE SUMMARY CONVERSION =====

  static StageSummaryModel _convertStageSummaryV2ToV1(
      StageSummaryModelV2 v2Stage) {
    return StageSummaryModel(
      totalInBedTime: v2Stage.totalInBedTime,
      totalAwakeTime: v2Stage.totalAwakeTime,
      totalNoDataTime: v2Stage.totalNoDataTime,
      totalLightSleepTime: v2Stage.totalLightSleepTime,
      totalSlowWaveSleepTime: v2Stage.totalSlowWaveSleepTime,
      totalRemSleepTime: v2Stage.totalRemSleepTime,
      sleepCycleCount: v2Stage.sleepCycleCount,
      disturbanceCount: v2Stage.disturbanceCount,
    );
  }

  static StageSummaryModelV2 _convertStageSummaryV1ToV2(
      StageSummaryModel v1Stage) {
    return StageSummaryModelV2(
      totalInBedTime: v1Stage.totalInBedTime,
      totalAwakeTime: v1Stage.totalAwakeTime,
      totalNoDataTime: v1Stage.totalNoDataTime,
      totalLightSleepTime: v1Stage.totalLightSleepTime,
      totalSlowWaveSleepTime: v1Stage.totalSlowWaveSleepTime,
      totalRemSleepTime: v1Stage.totalRemSleepTime,
      sleepCycleCount: v1Stage.sleepCycleCount,
      disturbanceCount: v1Stage.disturbanceCount,
    );
  }

  // ===== SLEEP NEEDED CONVERSION =====

  static SleepNeededModel _convertSleepNeededV2ToV1(
      SleepNeededModelV2 v2Needed) {
    return SleepNeededModel(
      baseline: v2Needed.baseline,
      needFromSleepDebt: v2Needed.needFromSleepDebt,
      needFromRecentStrain: v2Needed.needFromRecentStrain,
      needFromRecentNap: v2Needed.needFromRecentNap,
    );
  }

  static SleepNeededModelV2 _convertSleepNeededV1ToV2(
      SleepNeededModel v1Needed) {
    return SleepNeededModelV2(
      baseline: v1Needed.baseline,
      needFromSleepDebt: v1Needed.needFromSleepDebt,
      needFromRecentStrain: v1Needed.needFromRecentStrain,
      needFromRecentNap: v1Needed.needFromRecentNap,
    );
  }
}
