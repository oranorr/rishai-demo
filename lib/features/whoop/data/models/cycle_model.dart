import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
// CYCLE:
// {id: 650800430, user_id: 57314, created_at: 2024-08-30T00:11:37.374Z, updated_at: 2024-08-30T06:28:17.545Z,
//  start: 2024-08-29T18:07:34.295Z, end: null, timezone_offset: +04:00,
// score_state: SCORED,
//score: {strain: 16.434042, kilojoule: 9811.742,
// average_heart_rate: 73, max_heart_rate: 172}}

class CycleModel {
  final int id;
  final int userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime start;
  final DateTime? end;
  final String scoreState;
  final CycleScore? score;

  CycleModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.start,
    required this.scoreState,
    this.updatedAt,
    this.end,
    this.score,
  });

  factory CycleModel.fromMap(Map<String, dynamic> map) {
    return CycleModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != 'null'
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      start: DateTime.parse(map['start'] as String),
      end: map['end'] != null ? DateTime.parse(map['end'] as String) : null,
      scoreState: map['score_state'] as String,
      score: map['score'] != 'null'
          ? CycleScore.fromMap(map['score'] as Map<String, dynamic>)
          : null,
    );
  }

  factory CycleModel.fromJson(String source) =>
      CycleModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CycleModel(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, start: $start, end: $end, scoreState: $scoreState, score: $score)';
  }
}

class CycleScore {
  final double strain;
  final double kilojoule;
  final int averageHeartRate;
  final int maxHeartRate;

  CycleScore({
    required this.strain,
    required this.kilojoule,
    required this.averageHeartRate,
    required this.maxHeartRate,
  });

  factory CycleScore.fromMap(Map<String, dynamic> map) {
    return CycleScore(
      strain: map['strain'] as double,
      kilojoule: map['kilojoule'] as double,
      averageHeartRate: map['average_heart_rate'] as int,
      maxHeartRate: map['max_heart_rate'] as int,
    );
  }

  factory CycleScore.fromJson(String source) =>
      CycleScore.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CycleScore(strain: $strain, kilojoule: $kilojoule, averageHeartRate: $averageHeartRate, maxHeartRate: $maxHeartRate)';
  }
}
