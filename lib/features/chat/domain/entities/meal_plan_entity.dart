import 'dart:convert';
import 'dart:math' as m;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/double_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';

part 'meal_plan_entity.g.dart';

String lorem =
    '"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."';

@HiveType(typeId: 6)
class MealPlanEntity extends HiveObject {
  MealPlanEntity({
    required this.meals,
  });

  factory MealPlanEntity.mock() {
    final rnd = m.Random();

    return MealPlanEntity(
      meals: List.generate(
        rnd.nextInt(4) + 1,
        (index) => Meal(
          isRegenerated: false,
          cookingInstructions: [],
          title: lorem.substring(1, rnd.nextInt(100) + 20),
          type: lorem.substring(1, rnd.nextInt(25) + 10),
          description: lorem.substring(1, rnd.nextInt(lorem.length - 1) + 10),
          macros: MacrosBreakdown(
            kcal: rnd.nextInt(500) + 150,
            protein: rnd.nextInt(60) + 10,
            carbs: rnd.nextInt(40) + 10,
            fat: rnd.nextInt(40) + 10,
          ),
          ingredients: List.generate(
            rnd.nextInt(10) + 3,
            (index) => Ingredient(
              emojiCode: '',
              title: lorem.substring(1, rnd.nextInt(lorem.length)),
              amount: '${lorem.substring(1, rnd.nextInt(10) + 1)} pcs',
            ),
          ),
        ),
      ),
    );
  }

  factory MealPlanEntity.fromMap(Map<String, dynamic> map) {
    // log(map.toString());
    return MealPlanEntity(
      meals: List<Meal>.from(
        (map['meals'] as List<dynamic>).map<Meal>(
          (x) => Meal.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  factory MealPlanEntity.fromJson(String source) =>
      MealPlanEntity.fromMap(json.decode(source) as Map<String, dynamic>);
  @HiveField(0)
  List<Meal> meals;

  MealPlanEntity copyWith({
    List<Meal>? meals,
  }) {
    return MealPlanEntity(
      meals: meals ?? this.meals,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'meals': meals.map((x) => x.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() => 'MealPlanEntity(meals: $meals)';

  @override
  bool operator ==(covariant MealPlanEntity other) {
    if (identical(this, other)) {
      return true;
    }

    return listEquals(other.meals, meals);
  }

  @override
  int get hashCode => meals.hashCode;
}

@HiveType(typeId: 7)
class Meal {
  Meal({
    required this.title,
    required this.type,
    required this.description,
    required this.macros,
    required this.ingredients,
    required this.cookingInstructions,
    required this.isRegenerated,
  });

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      title: map['title'] as String,
      type: map['type'] as String,
      description: map['description'] as String,
      macros: MacrosBreakdown.fromMap(map['macros'] as Map<String, dynamic>),
      ingredients: List<Ingredient>.from(
        (map['ingredients'] as List<dynamic>).map<Ingredient>(
          (x) => Ingredient.fromMap(x as Map<String, dynamic>),
        ),
      ),
      cookingInstructions: (map['cooking_instructions'] ?? []).cast<String>(),
      isRegenerated: map['isRegenerated'] ?? false,
    );
  }

  factory Meal.fromJson(String source) =>
      Meal.fromMap(json.decode(source) as Map<String, dynamic>);
  @HiveField(0)
  String title;
  @HiveField(1)
  String type;
  @HiveField(2)
  String description;
  @HiveField(3)
  MacrosBreakdown macros;
  @HiveField(4)
  List<Ingredient> ingredients;
  @HiveField(5)
  List<String> cookingInstructions;
  @HiveField(6)
  bool isRegenerated;

  Meal copyWith({
    String? title,
    String? type,
    String? description,
    MacrosBreakdown? macros,
    List<Ingredient>? ingredients,
    List<String>? cookingInstructions,
    bool? isRegenerated,
  }) {
    return Meal(
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      macros: macros ?? this.macros,
      ingredients: ingredients ?? this.ingredients,
      cookingInstructions: cookingInstructions ?? this.cookingInstructions,
      isRegenerated: isRegenerated ?? this.isRegenerated,
    );
  }

  ServingType get servingType {
    if (type.contains('breakfast') || type.contains('Breakfast')) {
      return ServingType.breakfast;
    } else if (type.contains('lunch') || type.contains('Lunch')) {
      return ServingType.lunch;
    } else if (type.contains('dinner') || type.contains('Dinner')) {
      return ServingType.dinner;
    } else if (type.contains('supper') || type.contains('Supper')) {
      return ServingType.supper;
    } else if (type.contains('snack') || type.contains('Snack')) {
      return ServingType.snack;
    } else {
      throw ArgumentError('Invalid meal type: $type');
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'type': type,
      'description': description,
      'macros': macros.toMap(),
      'ingredients': ingredients.map((x) => x.toMap()).toList(),
      'cooking_instructions': cookingInstructions,
      'isRegenerated': isRegenerated,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'Meal(title: $title, type: $type, description: $description, macros: $macros, ingredients: $ingredients, cookingInstructions: $cookingInstructions, isRegenerated: $isRegenerated)';
  }

  @override
  bool operator ==(covariant Meal other) {
    if (identical(this, other)) return true;

    return other.title == title &&
        other.type == type &&
        other.description == description &&
        other.macros == macros &&
        listEquals(other.ingredients, ingredients) &&
        other.cookingInstructions == cookingInstructions;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        type.hashCode ^
        description.hashCode ^
        macros.hashCode ^
        ingredients.hashCode ^
        cookingInstructions.hashCode;
  }

  Widget buildPieChart({
    required double dimension,
  }) {
    double calculatePercentage(int inc) {
      int sum = macros.carbs + macros.protein + macros.fat;
      return (inc * 100) / sum;
    }

    return SizedBox.square(
      dimension: dimension,
      child: PieChart(
        PieChartData(
          sectionsSpace: 6,
          sections: [
            PieChartSectionData(
              value: calculatePercentage(macros.carbs),
              color: RishColors.carbs,
              showTitle: false,
              radius: 4,
              // borderSide:
            ),
            PieChartSectionData(
              value: calculatePercentage(macros.protein),
              color: RishColors.protein,
              showTitle: false,
              radius: 4,
            ),
            PieChartSectionData(
              value: calculatePercentage(macros.fat),
              color: RishColors.fat,
              showTitle: false,
              radius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

@HiveType(typeId: 8)
class MacrosBreakdown {
  MacrosBreakdown({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MacrosBreakdown.fromMap(Map<String, dynamic> map) {
    return MacrosBreakdown(
      kcal: (map['kcal'] as num).toInt(),
      protein: (map['protein'] as num).toInt(),
      carbs: (map['carbs'] as num).toInt(),
      fat: (map['fat'] as num).toInt(),
    );
  }

  factory MacrosBreakdown.fromJson(String source) =>
      MacrosBreakdown.fromMap(json.decode(source) as Map<String, dynamic>);
  @HiveField(0)
  int kcal;
  @HiveField(1)
  int protein;
  @HiveField(2)
  int carbs;
  @HiveField(3)
  int fat;

  MacrosBreakdown copyWith({
    int? kcal,
    int? protein,
    int? carbs,
    int? fat,
  }) {
    return MacrosBreakdown(
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'kcal': kcal,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'MacrosBreakdown(kcal: $kcal, protein: $protein, carbs: $carbs, fat: $fat)';
  }

  @override
  bool operator ==(covariant MacrosBreakdown other) {
    if (identical(this, other)) {
      return true;
    }

    return other.kcal == kcal &&
        other.protein == protein &&
        other.carbs == carbs &&
        other.fat == fat;
  }

  @override
  int get hashCode {
    return kcal.hashCode ^ protein.hashCode ^ carbs.hashCode ^ fat.hashCode;
  }

  Widget buildTextMacros({required BuildContext context}) {
    return Text.rich(
      TextSpan(
        text: kcal.comaThisNumber(),
        style: context.styles.numsS,
        children: [
          TextSpan(text: ' kcals   ', style: context.styles.regularMedium),
          TextSpan(
            text: protein.comaThisNumber(),
            style: context.styles.numsS.copyWith(color: RishColors.protein),
          ),
          TextSpan(
            text: 'g P   ',
            style: context.styles.regularMedium
                .copyWith(color: RishColors.protein),
          ),
          TextSpan(
            text: carbs.comaThisNumber(),
            style: context.styles.numsS.copyWith(color: RishColors.carbs),
          ),
          TextSpan(
            text: 'g C   ',
            style:
                context.styles.regularMedium.copyWith(color: RishColors.carbs),
          ),
          TextSpan(
            text: fat.comaThisNumber(),
            style: context.styles.numsS.copyWith(color: RishColors.fat),
          ),
          TextSpan(
            text: 'g F   ',
            style: context.styles.regularMedium.copyWith(color: RishColors.fat),
          ),
        ],
      ),
    );
  }
}

@HiveType(typeId: 9)
class Ingredient {
  Ingredient({
    required this.emojiCode,
    required this.title,
    required this.amount,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      emojiCode: (map['emojicode'] ?? '') as String,
      title: map['title'] as String,
      amount: map['amount'] as String,
    );
  }

  factory Ingredient.fromJson(String source) =>
      Ingredient.fromMap(json.decode(source) as Map<String, dynamic>);
  @HiveField(0)
  String emojiCode;
  @HiveField(1)
  String title;
  @HiveField(2)
  String amount;

  Ingredient copyWith({
    String? emojiCode,
    String? title,
    String? amount,
  }) {
    return Ingredient(
      emojiCode: emojiCode ?? this.emojiCode,
      title: title ?? this.title,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'emojiCode': emojiCode,
      'title': title,
      'amount': amount,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'Ingredient(emojiCode: $emojiCode, title: $title, amount: $amount)';

  @override
  bool operator ==(covariant Ingredient other) {
    if (identical(this, other)) {
      return true;
    }

    return other.emojiCode == emojiCode &&
        other.title == title &&
        other.amount == amount;
  }

  @override
  int get hashCode => emojiCode.hashCode ^ title.hashCode ^ amount.hashCode;

  Widget buildIngredientTile({required BuildContext context}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Text(emojiCode),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              style: context.styles.regularMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: context.styles.regularMedium
                .copyWith(color: RishColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
