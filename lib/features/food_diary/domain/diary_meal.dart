// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:hive/hive.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';

part 'diary_meal.g.dart';

@HiveType(typeId: 20)
class DiaryMeal {
  @HiveField(0)
  final String title;
  @HiveField(1)
  final String type;
  @HiveField(2)
  final MacrosBreakdown macros;
  @HiveField(3)
  final bool isGeneratedMeal;

  DiaryMeal({
    required this.title,
    required this.type,
    required this.macros,
    required this.isGeneratedMeal,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'macros': macros.toMap(),
      'isGeneratedMeal': isGeneratedMeal,
    };
  }

  factory DiaryMeal.fromMap(Map<String, dynamic> map) {
    return DiaryMeal(
      title: map['title'],
      type: map['type'],
      macros: MacrosBreakdown.fromMap(map['macros']),
      isGeneratedMeal: map['isGeneratedMeal'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DiaryMeal &&
        other.title == title &&
        other.type == type &&
        other.macros == macros &&
        other.isGeneratedMeal == isGeneratedMeal;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        type.hashCode ^
        macros.hashCode ^
        isGeneratedMeal.hashCode;
  }

  @override
  String toString() =>
      'DiaryMeal(title: $title, type: $type, macros: $macros, isGeneratedMeal: $isGeneratedMeal)';
}
