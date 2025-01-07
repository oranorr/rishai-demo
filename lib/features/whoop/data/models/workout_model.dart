import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

part 'workout_model.g.dart';

@HiveType(typeId: 14)
class WorkoutModel {
  WorkoutModel({
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
  });

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      start: DateTime.parse(map['start'] as String),
      end: map['end'] != null ? DateTime.parse(map['end'] as String) : null,
      timezoneOffset: map['timezone_offset'] as String,
      sportId: map['sport_id'] as int,
      scoreState: map['score_state'] as String,
      score: map['score_state'] == 'SCORED'
          ? WorkoutScore.fromMap(map['score'])
          : null,
    );
  }

  factory WorkoutModel.fromJson(String source) =>
      WorkoutModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @HiveField(0)
  final int id;
  @HiveField(1)
  final int userId;
  @HiveField(2)
  final DateTime createdAt;
  @HiveField(3)
  final DateTime updatedAt;
  @HiveField(4)
  final DateTime start;
  @HiveField(5)
  final DateTime? end;
  @HiveField(6)
  final String timezoneOffset;
  @HiveField(7)
  final int sportId;
  @HiveField(8)
  final String scoreState;
  @HiveField(9)
  final WorkoutScore? score;

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
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'Workout(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, start: $start, end: $end, timezoneOffset: $timezoneOffset, sportId: $sportId, scoreState: $scoreState, score: $score)';
  }
}

@HiveType(typeId: 15)
class WorkoutScore {
  WorkoutScore({
    required this.strain,
    required this.averageHeartRate,
    required this.maxHeartRate,
    required this.kilojoule,
    required this.percentRecorded,
    required this.distanceMeter,
  });

  factory WorkoutScore.fromMap(Map<String, dynamic> map) {
    return WorkoutScore(
      strain: map['strain'] as double,
      averageHeartRate: map['average_heart_rate'] as int,
      maxHeartRate: map['max_heart_rate'] as int,
      kilojoule: map['kilojoule'] as double,
      percentRecorded: map['percent_recorded'] as double,
      distanceMeter: map['distance_meter'] as double,
    );
  }

  factory WorkoutScore.fromJson(String source) =>
      WorkoutScore.fromMap(json.decode(source) as Map<String, dynamic>);
  @HiveField(0)
  final double strain;
  @HiveField(1)
  final int averageHeartRate;
  @HiveField(2)
  final int maxHeartRate;
  @HiveField(3)
  final double kilojoule;
  @HiveField(4)
  final double percentRecorded;
  @HiveField(5)
  final double distanceMeter;

  WorkoutScore copyWith({
    double? strain,
    int? averageHeartRate,
    int? maxHeartRate,
    double? kilojoule,
    double? percentRecorded,
    double? distanceMeter,
  }) {
    return WorkoutScore(
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
    return 'WorkoutScore(strain: $strain, averageHeartRate: $averageHeartRate, maxHeartRate: $maxHeartRate, kilojoule: $kilojoule, percentRecorded: $percentRecorded, distanceMeter: $distanceMeter)';
  }

  @override
  bool operator ==(covariant WorkoutScore other) {
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
