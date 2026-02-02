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

  /// Безопасный парсинг для случаев, когда WHOOP отдает null/неожиданные типы.
  /// Возвращает null, если обязательные поля отсутствуют или некорректны.
  static CycleModel? tryFromMap(Map<String, dynamic> map) {
    final id = _asInt(map['id']);
    final userId = _asInt(map['user_id']);
    final createdAt = _asDateTime(map['created_at']);
    final start = _asDateTime(map['start']);
    final scoreState = _asString(map['score_state']);

    if (id == null ||
        userId == null ||
        createdAt == null ||
        start == null ||
        scoreState == null ||
        scoreState.isEmpty) {
      return null;
    }

    final updatedAt = _asDateTime(map['updated_at']);
    final end = _asDateTime(map['end']);
    final scoreMap = _asMap(map['score']);
    final score = scoreMap != null ? CycleScore.tryFromMap(scoreMap) : null;

    return CycleModel(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      start: start,
      end: end,
      scoreState: scoreState,
      score: score,
    );
  }

  factory CycleModel.fromMap(Map<String, dynamic> map) {
    final parsed = tryFromMap(map);
    if (parsed == null) {
      throw const FormatException('Invalid CycleModel data');
    }
    return parsed;
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

  /// Безопасный парсинг для случаев, когда WHOOP отдает null/неожиданные типы.
  /// Возвращает null, если обязательные поля отсутствуют или некорректны.
  static CycleScore? tryFromMap(Map<String, dynamic> map) {
    final strain = _asDouble(map['strain']);
    final kilojoule = _asDouble(map['kilojoule']);
    final averageHeartRate = _asInt(map['average_heart_rate']);
    final maxHeartRate = _asInt(map['max_heart_rate']);

    if (strain == null ||
        kilojoule == null ||
        averageHeartRate == null ||
        maxHeartRate == null) {
      return null;
    }

    return CycleScore(
      strain: strain,
      kilojoule: kilojoule,
      averageHeartRate: averageHeartRate,
      maxHeartRate: maxHeartRate,
    );
  }

  factory CycleScore.fromMap(Map<String, dynamic> map) {
    final parsed = tryFromMap(map);
    if (parsed == null) {
      throw const FormatException('Invalid CycleScore data');
    }
    return parsed;
  }

  factory CycleScore.fromJson(String source) =>
      CycleScore.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CycleScore(strain: $strain, kilojoule: $kilojoule, averageHeartRate: $averageHeartRate, maxHeartRate: $maxHeartRate)';
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
