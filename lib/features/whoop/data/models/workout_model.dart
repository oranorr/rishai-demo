import 'dart:convert';
import 'dart:developer';

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

  /// Безопасный парсинг для случаев, когда WHOOP отдает null/неожиданные типы.
  /// Возвращает null, если обязательные поля отсутствуют или некорректны.
  static WorkoutModel? tryFromMap(Map<String, dynamic> map) {
    final id = _asString(map['id']);
    final userId = _asInt(map['user_id']);
    final createdAt = _asDateTime(map['created_at']);
    final updatedAt = _asDateTime(map['updated_at']);
    final start = _asDateTime(map['start']);
    final timezoneOffset = _asString(map['timezone_offset']);
    final sportId = _asInt(map['sport_id']);
    final scoreState = _asString(map['score_state']);

    if (id == null ||
        id.isEmpty ||
        userId == null ||
        createdAt == null ||
        updatedAt == null ||
        start == null ||
        timezoneOffset == null ||
        timezoneOffset.isEmpty ||
        sportId == null ||
        scoreState == null ||
        scoreState.isEmpty) {
      return null;
    }

    final end = _asDateTime(map['end']);
    final scoreMap = _asMap(map['score']);
    final score = scoreState == 'SCORED' && scoreMap != null
        ? WorkoutScore.tryFromMap(scoreMap)
        : null;

    return WorkoutModel(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      start: start,
      end: end,
      timezoneOffset: timezoneOffset,
      sportId: sportId,
      scoreState: scoreState,
      score: score,
    );
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    log(map.toString());
    final parsed = tryFromMap(map);
    if (parsed == null) {
      throw const FormatException('Invalid WorkoutModel data');
    }
    return parsed;
  }

  factory WorkoutModel.fromJson(String source) =>
      WorkoutModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @HiveField(0)
  final String id;
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

  /// Безопасный парсинг для случаев, когда WHOOP отдает null/неожиданные типы.
  /// Возвращает null, если обязательные поля отсутствуют или некорректны.
  static WorkoutScore? tryFromMap(Map<String, dynamic> map) {
    final strain = _asDouble(map['strain']);
    final averageHeartRate = _asInt(map['average_heart_rate']);
    final maxHeartRate = _asInt(map['max_heart_rate']);
    final kilojoule = _asDouble(map['kilojoule']);
    final percentRecorded = _asDouble(map['percent_recorded']);
    final distanceMeter = _asDouble(map['distance_meter']) ?? 0.0;

    if (strain == null ||
        averageHeartRate == null ||
        maxHeartRate == null ||
        kilojoule == null ||
        percentRecorded == null) {
      return null;
    }

    return WorkoutScore(
      strain: strain,
      averageHeartRate: averageHeartRate,
      maxHeartRate: maxHeartRate,
      kilojoule: kilojoule,
      percentRecorded: percentRecorded,
      distanceMeter: distanceMeter,
    );
  }

  factory WorkoutScore.fromMap(Map<String, dynamic> map) {
    final parsed = tryFromMap(map);
    if (parsed == null) {
      throw const FormatException('Invalid WorkoutScore data');
    }
    return parsed;
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
