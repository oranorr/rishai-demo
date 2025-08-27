import 'dart:convert';

/// Модель цикла для WHOOP API v2 с поддержкой UUID
/// Поддерживает как UUID (v2) так и int (v1) ID для обратной совместимости
class CycleModelV2 {
  CycleModelV2({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.start,
    required this.scoreState,
    this.updatedAt,
    this.end,
    this.score,
    this.activityV1Id,
  }); // Для обратной совместимости с v1

  factory CycleModelV2.fromMap(Map<String, dynamic> map) {
    return CycleModelV2(
      id: map['id'], // Может быть String (UUID) в v2 или int в v1
      userId: map['user_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != 'null'
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      start: DateTime.parse(map['start'] as String),
      end: map['end'] != null ? DateTime.parse(map['end'] as String) : null,
      scoreState: map['score_state'] as String,
      score: map['score'] != 'null'
          ? CycleScoreV2.fromMap(map['score'] as Map<String, dynamic>)
          : null,
      activityV1Id:
          map['activity_v1_id'] as int?, // Поле для обратной совместимости
    );
  }

  factory CycleModelV2.fromJson(String source) =>
      CycleModelV2.fromMap(json.decode(source) as Map<String, dynamic>);

  final dynamic id; // String (UUID) в v2, int в v1
  final int userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime start;
  final DateTime? end;
  final String scoreState;
  final CycleScoreV2? score;
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
    return 'CycleModelV2(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, start: $start, end: $end, scoreState: $scoreState, score: $score, activityV1Id: $activityV1Id)';
  }
}

/// Модель оценки цикла для v2
class CycleScoreV2 {
  CycleScoreV2({
    required this.strain,
    required this.kilojoule,
    required this.averageHeartRate,
    required this.maxHeartRate,
  });

  factory CycleScoreV2.fromMap(Map<String, dynamic> map) {
    return CycleScoreV2(
      strain: map['strain'] as double,
      kilojoule: map['kilojoule'] as double,
      averageHeartRate: map['average_heart_rate'] as int,
      maxHeartRate: map['max_heart_rate'] as int,
    );
  }

  factory CycleScoreV2.fromJson(String source) =>
      CycleScoreV2.fromMap(json.decode(source) as Map<String, dynamic>);

  final double strain;
  final double kilojoule;
  final int averageHeartRate;
  final int maxHeartRate;

  @override
  String toString() {
    return 'CycleScoreV2(strain: $strain, kilojoule: $kilojoule, averageHeartRate: $averageHeartRate, maxHeartRate: $maxHeartRate)';
  }
}
