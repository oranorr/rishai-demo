import 'dart:convert';

class SleepModel {
  SleepModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.start,
    required this.end,
    required this.nap,
    required this.scoreState,
    this.score,
  });

  factory SleepModel.fromMap(Map<String, dynamic> json) {
    // log(json.toString());
    return SleepModel(
      id: json['id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      nap: json['nap'] ?? false,
      scoreState: json['score_state'],
      score: json['score_state'] == 'SCORED'
          ? SleepScoreModel.fromMap(json['score'] as Map<String, dynamic>)
          : null,
    );
  }
  final int id;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime start;
  final DateTime end;
  final bool nap;
  final String scoreState;
  final SleepScoreModel? score;

  @override
  String toString() {
    return 'SleepModel(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, start: $start, end: $end, nap: $nap, scoreState: $scoreState, score: $score)';
  }
}

class SleepScoreModel {
  SleepScoreModel({
    required this.stageSummary,
    required this.sleepNeeded,
    this.respiratoryRate,
    this.sleepPerformancePercentage,
    this.sleepConsistencyPercentage,
    this.sleepEfficiencyPercentage,
  });

  factory SleepScoreModel.fromMap(Map<String, dynamic> map) {
    return SleepScoreModel(
      stageSummary: map['stage_summary'] != null
          ? StageSummaryModel.fromMap(
              map['stage_summary'] as Map<String, dynamic>,
            )
          : null,
      sleepNeeded: map['sleep_needed'] != null
          ? SleepNeededModel.fromMap(
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
  final StageSummaryModel? stageSummary;
  final SleepNeededModel? sleepNeeded;
  final double? respiratoryRate;
  final double? sleepPerformancePercentage;
  final double? sleepConsistencyPercentage;
  final double? sleepEfficiencyPercentage;

  @override
  String toString() {
    return 'SleepScoreModel(stageSummary: $stageSummary, sleepNeeded: $sleepNeeded, respiratoryRate: $respiratoryRate, sleepPerformancePercentage: $sleepPerformancePercentage, sleepConsistencyPercentage: $sleepConsistencyPercentage, sleepEfficiencyPercentage: $sleepEfficiencyPercentage)';
  }
}

class StageSummaryModel {
  StageSummaryModel({
    required this.totalInBedTime,
    required this.totalAwakeTime,
    required this.totalNoDataTime,
    required this.totalLightSleepTime,
    required this.totalSlowWaveSleepTime,
    required this.totalRemSleepTime,
    required this.sleepCycleCount,
    required this.disturbanceCount,
  });

  factory StageSummaryModel.fromMap(Map<String, dynamic> json) {
    return StageSummaryModel(
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
    return 'StageSummaryModel(totalInBedTime: $totalInBedTime, totalAwakeTime: $totalAwakeTime, totalNoDataTime: $totalNoDataTime, totalLightSleepTime: $totalLightSleepTime, totalSlowWaveSleepTime: $totalSlowWaveSleepTime, totalRemSleepTime: $totalRemSleepTime, sleepCycleCount: $sleepCycleCount, disturbanceCount: $disturbanceCount)';
  }
}

class SleepNeededModel {
  SleepNeededModel({
    required this.baseline,
    required this.needFromSleepDebt,
    required this.needFromRecentStrain,
    required this.needFromRecentNap,
  });

  factory SleepNeededModel.fromMap(Map<String, dynamic> json) {
    return SleepNeededModel(
      baseline: Duration(milliseconds: json['baseline_milli']),
      needFromSleepDebt:
          Duration(milliseconds: json['need_from_sleep_debt_milli']),
      needFromRecentStrain:
          Duration(milliseconds: json['need_from_recent_strain_milli']),
      needFromRecentNap:
          Duration(milliseconds: json['need_from_recent_nap_milli']),
    );
  }

  factory SleepNeededModel.fromJson(String source) =>
      SleepNeededModel.fromMap(json.decode(source) as Map<String, dynamic>);
  final Duration baseline;
  final Duration needFromSleepDebt;
  final Duration needFromRecentStrain;
  final Duration needFromRecentNap;

  @override
  String toString() {
    return 'SleepNeededModel(baseline: $baseline, needFromSleepDebt: $needFromSleepDebt, needFromRecentStrain: $needFromRecentStrain, needFromRecentNap: $needFromRecentNap)';
  }
}
