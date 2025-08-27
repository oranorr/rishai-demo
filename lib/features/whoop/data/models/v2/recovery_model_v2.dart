// RecoveryModelV2 - независимая модель для v2 API

/// Модель восстановления для WHOOP API v2 с поддержкой UUID
/// Поддерживает как UUID (v2) так и int (v1) ID для обратной совместимости
class RecoveryModelV2 {
  RecoveryModelV2({
    required this.cycleId,
    required this.sleepId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.scoreState,
    this.score,
    this.activityV1Id, // Для обратной совместимости с v1
  });

  factory RecoveryModelV2.fromJson(Map<String, dynamic> json) {
    return RecoveryModelV2(
      cycleId: json['cycle_id'], // Может быть String (UUID) в v2 или int в v1
      sleepId: json['sleep_id'], // Может быть String (UUID) в v2 или int в v1
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      scoreState: json['score_state'],
      score: json['score'] != null
          ? RecoveryScoreModelV2.fromJson(json['score'])
          : null,
      activityV1Id:
          json['activity_v1_id'] as int?, // Поле для обратной совместимости
    );
  }

  final dynamic cycleId; // String (UUID) в v2, int в v1
  final dynamic sleepId; // String (UUID) в v2, int в v1
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String scoreState;
  final RecoveryScoreModelV2? score;
  final int? activityV1Id; // Для обратной совместимости

  /// Получить cycleId как строку (для v2 UUID или v1 int.toString())
  String get cycleIdAsString => cycleId.toString();

  /// Получить cycleId как int (для обратной совместимости)
  int? get cycleIdAsInt => cycleId is int ? cycleId as int : null;

  /// Получить cycleId как UUID (для v2)
  String? get cycleIdAsUuid => cycleId is String ? cycleId as String : null;

  /// Получить sleepId как строку (для v2 UUID или v1 int.toString())
  String get sleepIdAsString => sleepId.toString();

  /// Получить sleepId как int (для обратной совместимости)
  int? get sleepIdAsInt => sleepId is int ? sleepId as int : null;

  /// Получить sleepId как UUID (для v2)
  String? get sleepIdAsUuid => sleepId is String ? sleepId as String : null;

  /// Проверить, является ли cycleId UUID
  bool get isCycleIdUuid => cycleId is String;

  /// Проверить, является ли sleepId UUID
  bool get isSleepIdUuid => sleepId is String;

  @override
  String toString() {
    return 'RecoveryModelV2(cycleId: $cycleId, sleepId: $sleepId, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, scoreState: $scoreState, score: $score, activityV1Id: $activityV1Id)';
  }
}

/// Модель оценки восстановления для v2
class RecoveryScoreModelV2 {
  RecoveryScoreModelV2({
    required this.userCalibrating,
    required this.recoveryScore,
    required this.restingHeartRate,
    required this.hrvRmssd,
    this.spo2Percentage,
    this.skinTemp,
  });

  factory RecoveryScoreModelV2.fromJson(Map<String, dynamic> json) {
    return RecoveryScoreModelV2(
      userCalibrating: json['user_calibrating'],
      recoveryScore: json['recovery_score'],
      restingHeartRate: json['resting_heart_rate'],
      hrvRmssd:
          Duration(milliseconds: (json['hrv_rmssd_milli'] * 1000).round()),
      spo2Percentage: (json['spo2_percentage'] as num?)?.toDouble(),
      skinTemp: (json['skin_temp_celsius'] as num?)?.toDouble(),
    );
  }

  final bool userCalibrating;
  final double recoveryScore;
  final double restingHeartRate;
  final Duration hrvRmssd;
  final double? spo2Percentage;
  final double? skinTemp;

  @override
  String toString() {
    return 'RecoveryScoreModelV2(userCalibrating: $userCalibrating, recoveryScore: $recoveryScore, restingHeartRate: $restingHeartRate, hrvRmssd: $hrvRmssd, spo2Percentage: $spo2Percentage, skinTemp: $skinTemp)';
  }
}
