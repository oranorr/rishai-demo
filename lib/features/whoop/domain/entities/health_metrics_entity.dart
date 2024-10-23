// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class HealthMetricsEntity {
  final int bmi;
  final int lastTdee;
  final int bmr;
  final int bodyFatPerc;
  HealthMetricsEntity({
    required this.bmi,
    required this.lastTdee,
    required this.bmr,
    required this.bodyFatPerc,
  });

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

  List<String> toListNames() => ['BMI', '24H Cal Burn', 'BMR'];

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

  factory HealthMetricsEntity.fromMap(Map<String, dynamic> map) {
    return HealthMetricsEntity(
      bmi: map['bmi'] as int,
      lastTdee: map['lastTdee'] as int,
      bmr: map['bmr'] as int,
      bodyFatPerc: map['bodyFatPerc'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory HealthMetricsEntity.fromJson(String source) =>
      HealthMetricsEntity.fromMap(json.decode(source) as Map<String, dynamic>);

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
