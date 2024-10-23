import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'food_preferences_entity.g.dart';

@HiveType(typeId: 2)
class FoodPreferences {
  @HiveField(0)
  final List<String> diets;
  @HiveField(1)
  final List<String> cuisines;

  FoodPreferences({
    required this.diets,
    required this.cuisines,
  });

  FoodPreferences copyWith({
    List<String>? diets,
    List<String>? cuisines,
  }) {
    return FoodPreferences(
      diets: diets ?? this.diets,
      cuisines: cuisines ?? this.cuisines,
    );
  }

  @override
  String toString() => 'foodPreferences(diets: $diets, cuisines: $cuisines, )';

  // Map<String, dynamic> toMap() {
  //   return <String, dynamic>{
  //     'diets': diets,
  //     'cuisines': cuisines,
  //     'goal': goal,
  //   };
  // }

  factory FoodPreferences.fromMap(Map<String, dynamic> map) {
    return FoodPreferences(
      diets: List<String>.from((map['diets'] as List<dynamic>)),
      cuisines: List<String>.from((map['cuisines'] as List<dynamic>)),
    );
  }

  // String toJson() => json.encode(toMap());

  factory FoodPreferences.fromJson(String source) =>
      FoodPreferences.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant FoodPreferences other) {
    if (identical(this, other)) return true;

    return listEquals(other.diets, diets) &&
        listEquals(other.cuisines, cuisines);
  }

  @override
  int get hashCode => diets.hashCode ^ cuisines.hashCode;
}
