// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

part 'health_metrics_entity.g.dart';

@HiveType(typeId: 16)
class HealthMetricsEntity {
  @HiveField(0)
  final int bmi;
  @HiveField(1)
  final int lastTdee;
  @HiveField(2)
  final int bmr;
  @HiveField(3)
  final int bodyFatPerc;

  const HealthMetricsEntity({
    required this.bmi,
    required this.lastTdee,
    required this.bmr,
    required this.bodyFatPerc,
  });

  factory HealthMetricsEntity.fromMap(Map<String, dynamic> map) {
    return HealthMetricsEntity(
      bmi: map['bmi'] as int,
      lastTdee: map['lastTdee'] as int,
      bmr: map['bmr'] as int,
      bodyFatPerc: map['bodyFatPerc'] as int,
    );
  }

  factory HealthMetricsEntity.fromJson(String source) =>
      HealthMetricsEntity.fromMap(json.decode(source) as Map<String, dynamic>);

  HealthMetricsEntity copyWith({
    int? bmi,
    int? lastTdee,
    int? bmr,
    int? bodyFatPerc,
  }) {
    return HealthMetricsEntity(
      bmi: bmi ?? this.bmi,
      lastTdee: lastTdee ?? this.lastTdee,
      bmr: bmr ?? this.bmr,
      bodyFatPerc: bodyFatPerc ?? this.bodyFatPerc,
    );
  }

  List<String> toListNames() => ['BMI', '24h Cal Burn', 'BMR'];

  List<int> toList() {
    return [bmi, lastTdee, bmr];
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bmi': bmi,
      'lastTdee': lastTdee,
      'bmr': bmr,
      'bodyFatPerc': bodyFatPerc,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'HealthMetricsEntity(bmi: $bmi, lastTdee: $lastTdee, bmr: $bmr, bodyFatPerc: $bodyFatPerc)';
  }

  @override
  bool operator ==(covariant HealthMetricsEntity other) {
    if (identical(this, other)) return true;

    return other.bmi == bmi &&
        other.lastTdee == lastTdee &&
        other.bmr == bmr &&
        other.bodyFatPerc == bodyFatPerc;
  }

  @override
  int get hashCode {
    return bmi.hashCode ^
        lastTdee.hashCode ^
        bmr.hashCode ^
        bodyFatPerc.hashCode;
  }
}
