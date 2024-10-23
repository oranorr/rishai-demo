// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

part 'workout_model.g.dart';
// WORKOUT:
// {id: 1206115357, user_id: 57314, created_at: 2024-08-30T06:28:13.828Z,
// updated_at: 2024-08-30T06:28:17.415Z, start: 2024-08-30T05:30:00.875Z, end: 2024-08-30T06:10:29.061Z,
// timezone_offset: +04:00, sport_id: 44,
//  score_state: SCORED,
//   score:
//{strain: 11.6135, average_heart_rate: 121, max_heart_rate: 160, kilojoule: 1272.5337,
//  percent_recorded: 100.0, distance_meter: 0.0, altitude_gain_meter: 0.0, altitude_change_meter: 0.0,
//  zone_duration:
//{zone_zero_milli: 295123, zone_one_milli: 228790,
// zone_two_milli: 821907, zone_three_milli: 823815,
//zone_four_milli: 258590, zone_five_milli: 0}}}

@HiveType(typeId: 14)
class WorkoutModel {
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

  WorkoutModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.start,
    this.end,
    required this.timezoneOffset,
    required this.sportId,
    required this.scoreState,
    required this.score,
  });

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

  String toJson() => json.encode(toMap());

  factory WorkoutModel.fromJson(String source) =>
      WorkoutModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Workout(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, start: $start, end: $end, timezoneOffset: $timezoneOffset, sportId: $sportId, scoreState: $scoreState, score: $score)';
  }
}

@HiveType(typeId: 15)
class WorkoutScore {
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
  WorkoutScore({
    required this.strain,
    required this.averageHeartRate,
    required this.maxHeartRate,
    required this.kilojoule,
    required this.percentRecorded,
    required this.distanceMeter,
  });

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
