// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:hive/hive.dart';

import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/food_diary/domain/diary_meal.dart';

part 'welness_entity.g.dart';

@HiveType(typeId: 19)
class WelnessEntity {
  @HiveField(0)
  //нужен упрощенный
  final List<DiaryMeal> consumedMeals;
  @HiveField(1)
  final double welnessPercentage;
  @HiveField(2)
  final MacrosBreakdown consumedMacros;

  WelnessEntity({
    required this.consumedMeals,
    required this.welnessPercentage,
    required this.consumedMacros,
  });

  factory WelnessEntity.fromMap(Map<String, dynamic> map) {
    return WelnessEntity(
      consumedMeals: (map['consumedMeals'] as List<dynamic>?)
              ?.map((e) => DiaryMeal.fromMap(e as Map<String, dynamic>))
              .toList() ??
          <DiaryMeal>[],
      welnessPercentage: (map['welnessPercentage'] as num?)?.toDouble() ?? 0.0,
      consumedMacros: MacrosBreakdown.fromMap(
        (map['consumedMacros'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }

  /// [copyWith] Метод для создания копии WelnessEntity с возможностью обновления полей
  WelnessEntity copyWith({
    List<DiaryMeal>? consumedMeals,
    double? welnessPercentage,
    MacrosBreakdown? consumedMacros,
  }) {
    return WelnessEntity(
      consumedMeals: consumedMeals ?? this.consumedMeals,
      welnessPercentage: welnessPercentage ?? this.welnessPercentage,
      consumedMacros: consumedMacros ?? this.consumedMacros,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'consumedMeals': consumedMeals.map((e) => e.toMap()).toList(),
      'welnessPercentage': welnessPercentage,
      'consumedMacros': consumedMacros.toMap(),
    };
  }

  @override
  bool operator ==(covariant WelnessEntity other) {
    if (identical(this, other)) return true;

    return other.welnessPercentage == welnessPercentage &&
        other.consumedMacros == consumedMacros &&
        _listEquals(other.consumedMeals, consumedMeals);
  }

  @override
  int get hashCode {
    return welnessPercentage.hashCode ^
        consumedMacros.hashCode ^
        consumedMeals.fold(0, (prev, element) => prev ^ element.hashCode);
  }

  /// Сравнивает два списка DiaryMeal
  bool _listEquals(List<DiaryMeal> a, List<DiaryMeal> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'WelnessEntity(consumedMeals: $consumedMeals, welnessPercentage: $welnessPercentage, consumedMacros: $consumedMacros)';
}
