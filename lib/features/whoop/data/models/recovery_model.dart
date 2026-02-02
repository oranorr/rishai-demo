class RecoveryModel {
  RecoveryModel({
    required this.cycleId,
    required this.sleepId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.scoreState,
    this.score,
  });

  /// Безопасный парсинг для случаев, когда WHOOP отдает null/неожиданные типы.
  /// Возвращает null, если обязательные поля отсутствуют или некорректны.
  static RecoveryModel? tryFromJson(Map<String, dynamic> json) {
    final cycleId = _asInt(json['cycle_id']);
    final sleepId = _asString(json['sleep_id']);
    final userId = _asInt(json['user_id']);
    final createdAt = _asDateTime(json['created_at']);
    final updatedAt = _asDateTime(json['updated_at']);
    final scoreState = _asString(json['score_state']);

    if (cycleId == null ||
        sleepId == null ||
        sleepId.isEmpty ||
        userId == null ||
        createdAt == null ||
        updatedAt == null ||
        scoreState == null ||
        scoreState.isEmpty) {
      return null;
    }

    final scoreMap = _asMap(json['score']);
    final score =
        scoreMap != null ? RecoveryScoreModel.tryFromJson(scoreMap) : null;

    return RecoveryModel(
      cycleId: cycleId,
      sleepId: sleepId,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      scoreState: scoreState,
      score: score,
    );
  }

  factory RecoveryModel.fromJson(Map<String, dynamic> json) {
    final parsed = tryFromJson(json);
    if (parsed == null) {
      throw const FormatException('Invalid RecoveryModel data');
    }
    return parsed;
  }
  final int cycleId;
  final String sleepId;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String scoreState;
  final RecoveryScoreModel? score;

  // RecoveryEntity toEntity() {
  //   return RecoveryEntity(
  //     cycleId: cycleId,
  //     sleepId: sleepId,
  //     userId: userId,
  //     createdAt: createdAt,
  //     updatedAt: updatedAt,
  //     scoreState: ScoreStateEntity.fromJson(scoreState),
  //     scoreEntity: score?.toEntity(),
  //   );
  // }

  @override
  String toString() {
    return 'RecoveryModel(cycleId: $cycleId, sleepId: $sleepId, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, scoreState: $scoreState, score: $score)';
  }
}

class RecoveryScoreModel {
  RecoveryScoreModel({
    required this.userCalibrating,
    required this.recoveryScore,
    required this.restingHeartRate,
    required this.hrvRmssd,
    this.spo2Percentage,
    this.skinTemp,
  });

  /// Безопасный парсинг для случаев, когда WHOOP отдает null/неожиданные типы.
  /// Возвращает null, если обязательные поля отсутствуют или некорректны.
  static RecoveryScoreModel? tryFromJson(Map<String, dynamic> json) {
    final userCalibrating = _asBool(json['user_calibrating']);
    final recoveryScore = _asDouble(json['recovery_score']);
    final restingHeartRate = _asDouble(json['resting_heart_rate']);
    final hrvRmssdMillis = _asDouble(json['hrv_rmssd_milli']);

    if (userCalibrating == null ||
        recoveryScore == null ||
        restingHeartRate == null ||
        hrvRmssdMillis == null) {
      return null;
    }

    return RecoveryScoreModel(
      userCalibrating: userCalibrating,
      recoveryScore: recoveryScore,
      restingHeartRate: restingHeartRate,
      hrvRmssd: Duration(milliseconds: (hrvRmssdMillis * 1000).round()),
      spo2Percentage: _asDouble(json['spo2_percentage']),
      skinTemp: _asDouble(json['skin_temp_celsius']),
    );
  }

  factory RecoveryScoreModel.fromJson(Map<String, dynamic> json) {
    final parsed = tryFromJson(json);
    if (parsed == null) {
      throw const FormatException('Invalid RecoveryScoreModel data');
    }
    return parsed;
  }
  final bool userCalibrating;
  final double recoveryScore;
  final double restingHeartRate;
  final Duration hrvRmssd;
  final double? spo2Percentage;
  final double? skinTemp;

  @override
  String toString() {
    return 'RecoveryScoreModel(userCalibrating: $userCalibrating, recoveryScore: $recoveryScore, restingHeartRate: $restingHeartRate, hrvRmssd: $hrvRmssd, spo2Percentage: $spo2Percentage, skinTemp: $skinTemp)';
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

Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null || value == 'null') return null;
  if (value is Map<String, dynamic>) return value;
  return null;
}
