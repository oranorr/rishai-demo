// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';

part 'whoop_data_entity.g.dart';

@HiveType(typeId: 12)
class WhoopDataEntity {
  @HiveField(0)
  final double weekTdeeAverage;
  @HiveField(1)
  final MacrosBreakdown macros;
  @HiveField(2)
  final DateTime askTime;
  @HiveField(3)
  final int lastTdee;

  const WhoopDataEntity({
    required this.weekTdeeAverage,
    required this.macros,
    required this.askTime,
    required this.lastTdee,
  });

  @override
  String toString() =>
      'WhoopDataEntity(weekTdeeAverage: $weekTdeeAverage, macros: $macros, askTime: $askTime, lastTdee: $lastTdee)';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'weekTdeeAverage': weekTdeeAverage,
      'macros': macros.toMap(),
      'askTime': askTime.millisecondsSinceEpoch,
      'lastTdee': lastTdee
    };
  }

  factory WhoopDataEntity.fromMap(Map<String, dynamic> map) {
    return WhoopDataEntity(
        weekTdeeAverage: map['weekTdeeAverage'] as double,
        macros: MacrosBreakdown.fromMap(map['macros'] as Map<String, dynamic>),
        askTime: DateTime.fromMillisecondsSinceEpoch(map['askTime'] as int),
        lastTdee: map['lastTdee']);
  }

  String toJson() => json.encode(toMap());

  factory WhoopDataEntity.fromJson(String source) =>
      WhoopDataEntity.fromMap(json.decode(source) as Map<String, dynamic>);

  WhoopDataEntity copyWith({
    double? weekTdeeAverage,
    MacrosBreakdown? macros,
    DateTime? askTime,
    int? lastTdee,
  }) {
    return WhoopDataEntity(
      weekTdeeAverage: weekTdeeAverage ?? this.weekTdeeAverage,
      macros: macros ?? this.macros,
      askTime: askTime ?? this.askTime,
      lastTdee: lastTdee ?? this.lastTdee,
    );
  }
}
