import 'dart:convert';

/// Модель сна для WHOOP API v2 с поддержкой UUID
/// Поддерживает как UUID (v2) так и int (v1) ID для обратной совместимости
class SleepModelV2 {
  SleepModelV2({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.start,
    required this.end,
    required this.nap,
    required this.scoreState,
    this.score,
    this.activityV1Id, // Для обратной совместимости с v1
  }); // Для обратной совместимости

  factory SleepModelV2.fromMap(Map<String, dynamic> json) {
    return SleepModelV2(
      id: json['id'], // Может быть String (UUID) в v2 или int в v1
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      nap: json['nap'] ?? false,
      scoreState: json['score_state'],
      score: json['score_state'] == 'SCORED'
          ? SleepScoreModelV2.fromMap(json['score'] as Map<String, dynamic>)
          : null,
      activityV1Id:
          json['activity_v1_id'] as int?, // Поле для обратной совместимости
    );
  }

  final dynamic id; // String (UUID) в v2, int в v1
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime start;
  final DateTime end;
  final bool nap;
  final String scoreState;
  final SleepScoreModelV2? score;
  final int? activityV1Id;

  /// Получить ID как строку (для v2 UUID или v1 int.toString())
  String get idAsString => id.toString();

  /// Получить ID как int (для обратной совместимости)
  int? get idAsInt => id is int ? id as int : activityV1Id;

  /// Получить ID как UUID (для v2)
  String? get idAsUuid => id is String ? id as String : null;

  /// Проверить, является ли ID UUID
  bool get isUuid => id is String;

  @override
  String toString() {
    return 'SleepModelV2(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, start: $start, end: $end, nap: $nap, scoreState: $scoreState, score: $score, activityV1Id: $activityV1Id)';
  }
}

/// Модель оценки сна для v2
class SleepScoreModelV2 {
  SleepScoreModelV2({
    required this.stageSummary,
    required this.sleepNeeded,
    this.respiratoryRate,
    this.sleepPerformancePercentage,
    this.sleepConsistencyPercentage,
    this.sleepEfficiencyPercentage,
  });

  factory SleepScoreModelV2.fromMap(Map<String, dynamic> map) {
    return SleepScoreModelV2(
      stageSummary: map['stage_summary'] != null
          ? StageSummaryModelV2.fromMap(
              map['stage_summary'] as Map<String, dynamic>,
            )
          : null,
      sleepNeeded: map['sleep_needed'] != null
          ? SleepNeededModelV2.fromMap(
              map['sleep_needed'] as Map<String, dynamic>,
            )
          : null,
      respiratoryRate: map['respiratory_rate'] != null
          ? map['respiratory_rate'] as double
          : null,
      sleepPerformancePercentage: map['sleep_performance_percentage'] != null
          ? map['sleep_performance_percentage'] as double
          : null,
      sleepConsistencyPercentage: map['sleep_consistency_percentage'] != null
          ? map['sleep_consistency_percentage'] as double
          : null,
      sleepEfficiencyPercentage: map['sleep_efficiency_percentage'] != null
          ? map['sleep_efficiency_percentage'] as double
          : null,
    );
  }

  final StageSummaryModelV2? stageSummary;
  final SleepNeededModelV2? sleepNeeded;
  final double? respiratoryRate;
  final double? sleepPerformancePercentage;
  final double? sleepConsistencyPercentage;
  final double? sleepEfficiencyPercentage;

  @override
  String toString() {
    return 'SleepScoreModelV2(stageSummary: $stageSummary, sleepNeeded: $sleepNeeded, respiratoryRate: $respiratoryRate, sleepPerformancePercentage: $sleepPerformancePercentage, sleepConsistencyPercentage: $sleepConsistencyPercentage, sleepEfficiencyPercentage: $sleepEfficiencyPercentage)';
  }
}

/// Модель сводки стадий сна для v2
class StageSummaryModelV2 {
  StageSummaryModelV2({
    required this.totalInBedTime,
    required this.totalAwakeTime,
    required this.totalNoDataTime,
    required this.totalLightSleepTime,
    required this.totalSlowWaveSleepTime,
    required this.totalRemSleepTime,
    required this.sleepCycleCount,
    required this.disturbanceCount,
  });

  factory StageSummaryModelV2.fromMap(Map<String, dynamic> json) {
    return StageSummaryModelV2(
      totalInBedTime: Duration(milliseconds: json['total_in_bed_time_milli']),
      totalAwakeTime: Duration(milliseconds: json['total_awake_time_milli']),
      totalNoDataTime: Duration(milliseconds: json['total_no_data_time_milli']),
      totalLightSleepTime:
          Duration(milliseconds: json['total_light_sleep_time_milli']),
      totalSlowWaveSleepTime:
          Duration(milliseconds: json['total_slow_wave_sleep_time_milli']),
      totalRemSleepTime:
          Duration(milliseconds: json['total_rem_sleep_time_milli']),
      sleepCycleCount: json['sleep_cycle_count'],
      disturbanceCount: json['disturbance_count'],
    );
  }

  final Duration totalInBedTime;
  final Duration totalAwakeTime;
  final Duration totalNoDataTime;
  final Duration totalLightSleepTime;
  final Duration totalSlowWaveSleepTime;
  final Duration totalRemSleepTime;
  final int sleepCycleCount;
  final int disturbanceCount;

  @override
  String toString() {
    return 'StageSummaryModelV2(totalInBedTime: $totalInBedTime, totalAwakeTime: $totalAwakeTime, totalNoDataTime: $totalNoDataTime, totalLightSleepTime: $totalLightSleepTime, totalSlowWaveSleepTime: $totalSlowWaveSleepTime, totalRemSleepTime: $totalRemSleepTime, sleepCycleCount: $sleepCycleCount, disturbanceCount: $disturbanceCount)';
  }
}

/// Модель потребности во сне для v2
class SleepNeededModelV2 {
  SleepNeededModelV2({
    required this.baseline,
    required this.needFromSleepDebt,
    required this.needFromRecentStrain,
    required this.needFromRecentNap,
  });

  factory SleepNeededModelV2.fromMap(Map<String, dynamic> json) {
    return SleepNeededModelV2(
      baseline: Duration(milliseconds: json['baseline_milli']),
      needFromSleepDebt:
          Duration(milliseconds: json['need_from_sleep_debt_milli']),
      needFromRecentStrain:
          Duration(milliseconds: json['need_from_recent_strain_milli']),
      needFromRecentNap:
          Duration(milliseconds: json['need_from_recent_nap_milli']),
    );
  }

  factory SleepNeededModelV2.fromJson(String source) =>
      SleepNeededModelV2.fromMap(json.decode(source) as Map<String, dynamic>);

  final Duration baseline;
  final Duration needFromSleepDebt;
  final Duration needFromRecentStrain;
  final Duration needFromRecentNap;

  @override
  String toString() {
    return 'SleepNeededModelV2(baseline: $baseline, needFromSleepDebt: $needFromSleepDebt, needFromRecentStrain: $needFromRecentStrain, needFromRecentNap: $needFromRecentNap)';
  }
}
