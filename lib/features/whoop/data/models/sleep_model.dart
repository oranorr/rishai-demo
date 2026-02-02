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

  /// Безопасный парсинг для случаев, когда WHOOP отдает null/неожиданные типы.
  /// Возвращает null, если обязательные поля отсутствуют или некорректны.
  static SleepModel? tryFromMap(Map<String, dynamic> json) {
    final id = _asString(json['id']);
    final userId = _asInt(json['user_id']);
    final createdAt = _asDateTime(json['created_at']);
    final updatedAt = _asDateTime(json['updated_at']);
    final start = _asDateTime(json['start']);
    final end = _asDateTime(json['end']);
    final scoreState = _asString(json['score_state']);
    final nap = _asBool(json['nap']) ?? false;

    if (id == null ||
        id.isEmpty ||
        userId == null ||
        createdAt == null ||
        updatedAt == null ||
        start == null ||
        end == null ||
        scoreState == null ||
        scoreState.isEmpty) {
      return null;
    }

    final scoreMap = _asMap(json['score']);
    final score = scoreState == 'SCORED' && scoreMap != null
        ? SleepScoreModel.tryFromMap(scoreMap)
        : null;

    return SleepModel(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      start: start,
      end: end,
      nap: nap,
      scoreState: scoreState,
      score: score,
    );
  }

  factory SleepModel.fromMap(Map<String, dynamic> json) {
    // log(json.toString());
    final parsed = tryFromMap(json);
    if (parsed == null) {
      throw const FormatException('Invalid SleepModel data');
    }
    return parsed;
  }
  final String id;
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

  /// Безопасный парсинг для случаев, когда WHOOP отдает null/неожиданные типы.
  /// Возвращает null, если обязательные поля отсутствуют или некорректны.
  static SleepScoreModel? tryFromMap(Map<String, dynamic> map) {
    final stageSummaryMap = _asMap(map['stage_summary']);
    final sleepNeededMap = _asMap(map['sleep_needed']);

    final stageSummary = stageSummaryMap != null
        ? StageSummaryModel.tryFromMap(stageSummaryMap)
        : null;
    final sleepNeeded = sleepNeededMap != null
        ? SleepNeededModel.tryFromMap(sleepNeededMap)
        : null;

    final respiratoryRate = _asDouble(map['respiratory_rate']);
    final sleepPerformancePercentage =
        _asDouble(map['sleep_performance_percentage']);
    final sleepConsistencyPercentage =
        _asDouble(map['sleep_consistency_percentage']);
    final sleepEfficiencyPercentage =
        _asDouble(map['sleep_efficiency_percentage']);

    return SleepScoreModel(
      stageSummary: stageSummary,
      sleepNeeded: sleepNeeded,
      respiratoryRate: respiratoryRate,
      sleepPerformancePercentage: sleepPerformancePercentage,
      sleepConsistencyPercentage: sleepConsistencyPercentage,
      sleepEfficiencyPercentage: sleepEfficiencyPercentage,
    );
  }

  factory SleepScoreModel.fromMap(Map<String, dynamic> map) {
    final parsed = tryFromMap(map);
    if (parsed == null) {
      throw const FormatException('Invalid SleepScoreModel data');
    }
    return parsed;
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

  /// Безопасный парсинг для случаев, когда WHOOP отдает null/неожиданные типы.
  /// Возвращает null, если обязательные поля отсутствуют или некорректны.
  static StageSummaryModel? tryFromMap(Map<String, dynamic> json) {
    final totalInBedTime = _asDuration(json['total_in_bed_time_milli']);
    final totalAwakeTime = _asDuration(json['total_awake_time_milli']);
    final totalNoDataTime = _asDuration(json['total_no_data_time_milli']);
    final totalLightSleepTime =
        _asDuration(json['total_light_sleep_time_milli']);
    final totalSlowWaveSleepTime =
        _asDuration(json['total_slow_wave_sleep_time_milli']);
    final totalRemSleepTime = _asDuration(json['total_rem_sleep_time_milli']);
    final sleepCycleCount = _asInt(json['sleep_cycle_count']);
    final disturbanceCount = _asInt(json['disturbance_count']);

    if (totalInBedTime == null ||
        totalAwakeTime == null ||
        totalNoDataTime == null ||
        totalLightSleepTime == null ||
        totalSlowWaveSleepTime == null ||
        totalRemSleepTime == null ||
        sleepCycleCount == null ||
        disturbanceCount == null) {
      return null;
    }

    return StageSummaryModel(
      totalInBedTime: totalInBedTime,
      totalAwakeTime: totalAwakeTime,
      totalNoDataTime: totalNoDataTime,
      totalLightSleepTime: totalLightSleepTime,
      totalSlowWaveSleepTime: totalSlowWaveSleepTime,
      totalRemSleepTime: totalRemSleepTime,
      sleepCycleCount: sleepCycleCount,
      disturbanceCount: disturbanceCount,
    );
  }

  factory StageSummaryModel.fromMap(Map<String, dynamic> json) {
    final parsed = tryFromMap(json);
    if (parsed == null) {
      throw const FormatException('Invalid StageSummaryModel data');
    }
    return parsed;
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

  /// Безопасный парсинг для случаев, когда WHOOP отдает null/неожиданные типы.
  /// Возвращает null, если обязательные поля отсутствуют или некорректны.
  static SleepNeededModel? tryFromMap(Map<String, dynamic> json) {
    final baseline = _asDuration(json['baseline_milli']);
    final needFromSleepDebt = _asDuration(json['need_from_sleep_debt_milli']);
    final needFromRecentStrain =
        _asDuration(json['need_from_recent_strain_milli']);
    final needFromRecentNap = _asDuration(json['need_from_recent_nap_milli']);

    if (baseline == null ||
        needFromSleepDebt == null ||
        needFromRecentStrain == null ||
        needFromRecentNap == null) {
      return null;
    }

    return SleepNeededModel(
      baseline: baseline,
      needFromSleepDebt: needFromSleepDebt,
      needFromRecentStrain: needFromRecentStrain,
      needFromRecentNap: needFromRecentNap,
    );
  }

  factory SleepNeededModel.fromMap(Map<String, dynamic> json) {
    final parsed = tryFromMap(json);
    if (parsed == null) {
      throw const FormatException('Invalid SleepNeededModel data');
    }
    return parsed;
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

// -------------------------
// Helpers (safe parsing)
// -------------------------
int? _asInt(dynamic value) {
  if (value == null || value == 'null') return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null || value == 'null') return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? _asBool(dynamic value) {
  if (value == null || value == 'null') return null;
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return null;
}

String? _asString(dynamic value) {
  if (value == null || value == 'null') return null;
  if (value is String) return value;
  return value.toString();
}

DateTime? _asDateTime(dynamic value) {
  if (value == null || value == 'null') return null;
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
  return null;
}

Duration? _asDuration(dynamic value) {
  final millis = _asInt(value);
  if (millis == null) return null;
  return Duration(milliseconds: millis);
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null || value == 'null') return null;
  if (value is Map<String, dynamic>) return value;
  return null;
}
