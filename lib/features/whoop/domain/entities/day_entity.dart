import 'package:hive/hive.dart';
import 'package:rishai/features/chat/domain/entities/chat_snapshot_entity.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/food_diary/domain/welness_entity.dart';
import 'package:rishai/features/whoop/domain/entities/health_metrics_entity.dart';

part 'day_entity.g.dart';

@HiveType(typeId: 12)
class DayEntity {
  DayEntity({
    required this.directusId,
    required this.weekTdeeAverage,
    required this.macros,
    required this.healthMetrics,
    required this.snap,
    required this.dateTime,
    this.cycleId,
    this.mealPlanEntity,
    this.welnessEntity,
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
      dateTime: map['dateTime'] is String
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(map['dateTime']))
          : map['dateTime'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['dateTime'])
              : DateTime.now(),
      snap: ChatSnapshotEntity.fromDirectus(
        map['chatSnap'],
      ),
      cycleId: map['cycleId'] != null ? int.parse(map['cycleId']) : null,
      welnessEntity: map['welnessEntity'] != null
          ? WelnessEntity.fromMap(map['welnessEntity'])
          : null,
    );
  }
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
  @HiveField(8)
  final WelnessEntity? welnessEntity;

  DayEntity copyWith({
    int? directusId,
    int? weekTdeeAverage,
    MacrosBreakdown? macros,
    HealthMetricsEntity? healthMetrics,
    MealPlanEntity? mealPlanEntity,
    DateTime? dateTime,
    ChatSnapshotEntity? snap,
    int? cycleId,
    WelnessEntity? welnessEntity,
  }) {
    return DayEntity(
      directusId: directusId ?? this.directusId,
      weekTdeeAverage: weekTdeeAverage ?? this.weekTdeeAverage,
      macros: macros ?? this.macros,
      healthMetrics: healthMetrics ?? this.healthMetrics,
      mealPlanEntity: mealPlanEntity ??
          this.mealPlanEntity, // [copyWith] Исправлен баг - теперь сохраняется существующий план питания
      dateTime: dateTime ?? this.dateTime,
      snap: snap ?? this.snap,
      cycleId: cycleId ?? this.cycleId,
      welnessEntity: welnessEntity ?? this.welnessEntity,
    );
  }

  Map<String, dynamic> toDirectus({required String userId}) {
    return {
      'userId': userId,
      'macros': macros.toMap(),
      'healthMetrics': healthMetrics.toMap(),
      'dateTime': dateTime.millisecondsSinceEpoch.toString(),
      'weekTdeeAverage': weekTdeeAverage,
      'mealPlan': mealPlanEntity?.toMap(),
      'chatSnap': snap.toDirectus(),
      'cycleId': cycleId?.toString(),
      'welnessEntity': welnessEntity?.toMap(),
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
        other.dateTime == dateTime &&
        other.welnessEntity == welnessEntity &&
        other.snap == snap;
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

  /// Группирует названия блюд по типам из последних дней
  static Map<String, List<String>> groupMealTitlesByType(List<DayEntity> days) {
    // Инициализируем map для хранения названий блюд
    final Map<String, List<String>> groupedMealTitles = {
      'breakfasts': [], // завтраки
      'mains': [], // основные блюда (обед, ужин, поздний ужин)
      'snacks': [], // перекусы
    };

    // Проходим по всем дням
    for (final day in days) {
      if (day.mealPlanEntity == null) continue;

      // Проходим по всем блюдам дня
      for (final meal in day.mealPlanEntity!.meals) {
        switch (meal.servingType) {
          case ServingType.breakfast:
            groupedMealTitles['breakfasts']!.add(meal.title);
          case ServingType.snack:
            groupedMealTitles['snacks']!.add(meal.title);
          case ServingType.lunch:
          case ServingType.dinner:
          case ServingType.supper:
            groupedMealTitles['mains']!.add(meal.title);
        }
      }
    }

    // Удаляем дубликаты названий
    groupedMealTitles['breakfasts'] =
        _removeDuplicateTitles(groupedMealTitles['breakfasts']!);
    groupedMealTitles['mains'] =
        _removeDuplicateTitles(groupedMealTitles['mains']!);
    groupedMealTitles['snacks'] =
        _removeDuplicateTitles(groupedMealTitles['snacks']!);

    return groupedMealTitles;
  }

  /// Удаляет дубликаты названий блюд
  static List<String> _removeDuplicateTitles(List<String> titles) {
    return titles.toSet().toList();
  }

  /// Получает историю названий блюд за последние N дней
  static Map<String, List<String>> getMealHistory(
    List<DayEntity> days, {
    int daysLimit = 7,
  }) {
    // Берем только последние N дней
    final recentDays =
        days.length > daysLimit ? days.sublist(days.length - daysLimit) : days;

    return groupMealTitlesByType(recentDays);
  }

  // String getDayTitle() {
  //   final now = DateTime.now();
  //   if (isToday) {
  //     return 'Today';
  //   }else if(now.difference(dateTime).inDays > 1 && now.difference(dateTime).inDays > 1)
  // }
}
