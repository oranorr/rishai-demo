import 'dart:convert';

/// Модель тренировки для WHOOP API v2 с поддержкой UUID
/// Поддерживает как UUID (v2) так и int (v1) ID для обратной совместимости
class WorkoutModelV2 {
  WorkoutModelV2({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.start,
    required this.timezoneOffset,
    required this.sportId,
    required this.scoreState,
    required this.score,
    this.end,
    this.activityV1Id, // Для обратной совместимости с v1
  }); // Для обратной совместимости

  factory WorkoutModelV2.fromMap(Map<String, dynamic> map) {
    return WorkoutModelV2(
      id: map['id'], // Может быть String (UUID) в v2 или int в v1
      userId: map['user_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      start: DateTime.parse(map['start'] as String),
      end: map['end'] != null ? DateTime.parse(map['end'] as String) : null,
      timezoneOffset: map['timezone_offset'] as String,
      sportId: map['sport_id'] as int,
      scoreState: map['score_state'] as String,
      score: map['score_state'] == 'SCORED'
          ? WorkoutScoreV2.fromMap(map['score'])
          : null,
      activityV1Id:
          map['activity_v1_id'] as int?, // Поле для обратной совместимости
    );
  }

  factory WorkoutModelV2.fromJson(String source) =>
      WorkoutModelV2.fromMap(json.decode(source) as Map<String, dynamic>);

  final dynamic id; // String (UUID) в v2, int в v1
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime start;
  final DateTime? end;
  final String timezoneOffset;
  final int sportId;
  final String scoreState;
  final WorkoutScoreV2? score;
  final int? activityV1Id;

  /// Получить ID как строку (для v2 UUID или v1 int.toString())
  String get idAsString => id.toString();

  /// Получить ID как int (для обратной совместимости)
  int? get idAsInt => id is int ? id as int : activityV1Id;

  /// Получить ID как UUID (для v2)
  String? get idAsUuid => id is String ? id as String : null;

  /// Проверить, является ли ID UUID
  bool get isUuid => id is String;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'start': start.millisecondsSinceEpoch,
      'end': end?.millisecondsSinceEpoch,
      'timezoneOffset': timezoneOffset,
      'sportId': sportId,
      'scoreState': scoreState,
      'score': score,
      'activityV1Id': activityV1Id,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'WorkoutModelV2(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, start: $start, end: $end, timezoneOffset: $timezoneOffset, sportId: $sportId, scoreState: $scoreState, score: $score, activityV1Id: $activityV1Id)';
  }
}

/// Модель оценки тренировки для v2
class WorkoutScoreV2 {
  WorkoutScoreV2({
    required this.strain,
    required this.averageHeartRate,
    required this.maxHeartRate,
    required this.kilojoule,
    required this.percentRecorded,
    required this.distanceMeter,
  });

  factory WorkoutScoreV2.fromMap(Map<String, dynamic> map) {
    return WorkoutScoreV2(
      strain: map['strain'] as double,
      averageHeartRate: map['average_heart_rate'] as int,
      maxHeartRate: map['max_heart_rate'] as int,
      kilojoule: map['kilojoule'] as double,
      percentRecorded: map['percent_recorded'] as double,
      distanceMeter: map['distance_meter'] as double,
    );
  }

  factory WorkoutScoreV2.fromJson(String source) =>
      WorkoutScoreV2.fromMap(json.decode(source) as Map<String, dynamic>);

  final double strain;
  final int averageHeartRate;
  final int maxHeartRate;
  final double kilojoule;
  final double percentRecorded;
  final double distanceMeter;

  WorkoutScoreV2 copyWith({
    double? strain,
    int? averageHeartRate,
    int? maxHeartRate,
    double? kilojoule,
    double? percentRecorded,
    double? distanceMeter,
  }) {
    return WorkoutScoreV2(
      strain: strain ?? this.strain,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      kilojoule: kilojoule ?? this.kilojoule,
      percentRecorded: percentRecorded ?? this.percentRecorded,
      distanceMeter: distanceMeter ?? this.distanceMeter,
    );
  }

  @override
  String toString() {
    return 'WorkoutScoreV2(strain: $strain, averageHeartRate: $averageHeartRate, maxHeartRate: $maxHeartRate, kilojoule: $kilojoule, percentRecorded: $percentRecorded, distanceMeter: $distanceMeter)';
  }

  @override
  bool operator ==(covariant WorkoutScoreV2 other) {
    if (identical(this, other)) return true;

    return other.strain == strain &&
        other.averageHeartRate == averageHeartRate &&
        other.maxHeartRate == maxHeartRate &&
        other.kilojoule == kilojoule &&
        other.percentRecorded == percentRecorded &&
        other.distanceMeter == distanceMeter;
  }

  @override
  int get hashCode {
    return strain.hashCode ^
        averageHeartRate.hashCode ^
        maxHeartRate.hashCode ^
        kilojoule.hashCode ^
        percentRecorded.hashCode ^
        distanceMeter.hashCode;
  }
}
