// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/whoop/domain/entities/health_metrics_entity.dart';

part 'day_entity.g.dart';

@HiveType(typeId: 12)
class DayEntity {
  @HiveField(0)
  final int directusId;
  @HiveField(1)
  final int weekTdeeAverage;
  @HiveField(2)
  final MacrosBreakdown macros;
  @HiveField(3)
  final HealthMetricsEntity healthMetrics;
  @HiveField(4)
  final MealPlanEntity? mealPlanEntity;
  @HiveField(5)
  final DateTime dateTime;
  @HiveField(6)
  final ChatSnapshotEntity snap;
  @HiveField(7)
  final int? cycleId;

  DayEntity({
    required this.directusId,
    required this.weekTdeeAverage,
    required this.macros,
    required this.healthMetrics,
    required this.snap,
    required this.dateTime,
    this.cycleId,
    this.mealPlanEntity,
  });

  factory DayEntity.empty({required int requestsLeft}) {
    return DayEntity(
      snap: ChatSnapshotEntity(
        messages: [],
        date: DateTime.now(),
        requestsLeft: requestsLeft,
      ),
      directusId: 0,
      dateTime: DateTime.now(),
      weekTdeeAverage: 0,
      macros: MacrosBreakdown(kcal: 0, protein: 0, carbs: 0, fat: 0),
      healthMetrics: const HealthMetricsEntity(
        bmi: 0,
        lastTdee: 0,
        bmr: 0,
        bodyFatPerc: 0,
      ),
    );
  }

  DayEntity copyWith({
    int? directusId,
    int? weekTdeeAverage,
    MacrosBreakdown? macros,
    HealthMetricsEntity? healthMetrics,
    MealPlanEntity? mealPlanEntity,
    DateTime? dateTime,
    ChatSnapshotEntity? snap,
    int? cycleId,
  }) {
    return DayEntity(
      directusId: directusId ?? this.directusId,
      weekTdeeAverage: weekTdeeAverage ?? this.weekTdeeAverage,
      macros: macros ?? this.macros,
      healthMetrics: healthMetrics ?? this.healthMetrics,
      mealPlanEntity: mealPlanEntity ?? this.mealPlanEntity,
      dateTime: dateTime ?? this.dateTime,
      snap: snap ?? this.snap,
      cycleId: cycleId ?? this.cycleId,
    );
  }

  factory DayEntity.fromMap(Map<String, dynamic> map) {
    return DayEntity(
      directusId: map['id'] as int,
      weekTdeeAverage: (map['weekTdeeAverage'] as num).toInt(),
      macros: MacrosBreakdown.fromMap(map['macros'] as Map<String, dynamic>),
      healthMetrics: HealthMetricsEntity.fromMap(
        map['healthMetrics'] as Map<String, dynamic>,
      ),
      mealPlanEntity: map['mealPlan'] != null
          ? MealPlanEntity.fromMap(map['mealPlan'] as Map<String, dynamic>)
          : null,
      dateTime: DateTime.fromMillisecondsSinceEpoch(int.parse(map['dateTime'])),
      snap: ChatSnapshotEntity.fromDirectus(
        map['chatSnap'],
      ),
      cycleId: map['cycleId'] != null ? int.parse(map['cycleId']) : null,
    );
  }

  Map<String, dynamic> toDirectus({required String userId}) {
    return {
      'userId': userId,
      'macros': macros.toMap(),
      'healthMetrics': healthMetrics.toMap(),
      'dateTime': dateTime.millisecondsSinceEpoch,
      'weekTdeeAverage': weekTdeeAverage,
      'mealPlan': mealPlanEntity?.toMap(),
      'chatSnap': snap.toDirectus(),
      'cycleId': cycleId,
    };
  }

  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  @override
  String toString() {
    return 'DayEntity(cycleId: $cycleId, directusId: $directusId, weekTdeeAverage: $weekTdeeAverage, macros: $macros, healthMetrics: $healthMetrics, mealPlanEntity: $mealPlanEntity, dateTime: $dateTime)';
  }

  @override
  bool operator ==(covariant DayEntity other) {
    if (identical(this, other)) return true;

    return other.directusId == directusId &&
        other.weekTdeeAverage == weekTdeeAverage &&
        other.macros == macros &&
        other.healthMetrics == healthMetrics &&
        other.mealPlanEntity == mealPlanEntity &&
        other.dateTime == dateTime;
  }

  @override
  int get hashCode {
    return directusId.hashCode ^
        weekTdeeAverage.hashCode ^
        macros.hashCode ^
        healthMetrics.hashCode ^
        mealPlanEntity.hashCode ^
        dateTime.hashCode;
  }

  List<Map<String, dynamic>> mockDays({
    required int length,
    required String id,
  }) {
    return List.generate(length, (int index) {
      DateTime subs = dateTime.subtract(Duration(days: length));
      return DayEntity(
        directusId: index,
        weekTdeeAverage: 10000 - index,
        macros: MacrosBreakdown(
          kcal: 100 - index,
          protein: 100 - index,
          carbs: 100 - index,
          fat: 100 - index,
        ),
        healthMetrics: healthMetrics,
        dateTime: subs.add(Duration(days: index)),
        mealPlanEntity: mealPlanEntity,
        snap: ChatSnapshotEntity(
          messages: [],
          date: subs.add(Duration(days: index)),
          requestsLeft: 13,
        ),
      ).toDirectus(userId: id);
    });
  }

  // String getDayTitle() {
  //   final now = DateTime.now();
  //   if (isToday) {
  //     return 'Today';
  //   }else if(now.difference(dateTime).inDays > 1 && now.difference(dateTime).inDays > 1)
  // }
}
