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

  factory RecoveryModel.fromJson(Map<String, dynamic> json) {
    return RecoveryModel(
      cycleId: json['cycle_id'],
      sleepId: json['sleep_id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      scoreState: json['score_state'],
      score: json['score'] != null
          ? RecoveryScoreModel.fromJson(json['score'])
          : null,
    );
  }
  final int cycleId;
  final int sleepId;
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

  factory RecoveryScoreModel.fromJson(Map<String, dynamic> json) {
    return RecoveryScoreModel(
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
    return 'RecoveryScoreModel(userCalibrating: $userCalibrating, recoveryScore: $recoveryScore, restingHeartRate: $restingHeartRate, hrvRmssd: $hrvRmssd, spo2Percentage: $spo2Percentage, skinTemp: $skinTemp)';
  }
}
