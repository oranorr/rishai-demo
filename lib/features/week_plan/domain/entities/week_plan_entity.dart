// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert' show jsonDecode;

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';

/// Сущность недельного плана: только сеть (Directus) + [WeekPlanBloc] в памяти,
/// без отдельного бокса Hive.
class WeekPlanEntity extends Equatable {
  const WeekPlanEntity({
    required this.userId,
    required this.plans,
    required this.startDate,
    required this.endDate,
    required this.fitnessGoal,
    required this.dietaryPreferences,
    required this.cuisines,
    required this.mealsTypes,
  });

  factory WeekPlanEntity.create({
    required String userId,
    required List<MealPlanEntity> plans,
    required DateTime startDate,
  }) {
    // ✅ Отладочные логи для проверки userId
    print('[WeekPlanEntity.create] Создание плана с userId: $userId');
    print(
        '[WeekPlanEntity.create] Пользователь авторизован: ${userId != '-1'}');

    // final tomorrow = DateTime.now().add(const Duration(days: 1));

    final endDate =
        startDate.add(const Duration(days: 4)); // +4 так как включая завтра

    final weekPlan = WeekPlanEntity(
      userId: userId,
      plans: plans,
      startDate: startDate,
      endDate: endDate,
      fitnessGoal: '',
      dietaryPreferences: '',
      cuisines: const [],
      mealsTypes: const [],
    );

    print('[WeekPlanEntity.create] Создан план с userId: ${weekPlan.userId}');
    return weekPlan;
  }

  factory WeekPlanEntity.fromMap(Object? source) {
    if (source is! Map) {
      throw ArgumentError(
        'WeekPlanEntity.fromMap: expected Map, got: $source',
      );
    }
    // Directus/JSON: [Map<dynamic, dynamic>], [startDate] как String/int/double.
    final m = Map<String, dynamic>.from(source);

    // ✅ Отладочные логи для проверки десериализации
    final userId = m['userId'].toString();
    print('[WeekPlanEntity.fromMap] Десериализация плана с userId: $userId');
    print(
        '[WeekPlanEntity.fromMap] Данные из Directus: ${m.keys.join(', ')}');

    // Directus JSON-поле иногда отдаётся одной строкой, не массивом.
    dynamic rawPlans = m['mealPlans'];
    if (rawPlans is String) {
      final decoded = jsonDecode(rawPlans);
      rawPlans = decoded;
    }
    if (rawPlans is! List || rawPlans.isEmpty) {
      throw ArgumentError(
        'WeekPlanEntity.fromMap: mealPlans must be a non-empty List, got: $rawPlans',
      );
    }

    return WeekPlanEntity(
      userId: userId,
      plans: <MealPlanEntity>[
        for (final plan in rawPlans)
          if (plan is String)
            MealPlanEntity.fromMap(
              Map<String, dynamic>.from(jsonDecode(plan) as Map),
            )
          else if (plan is Map)
            MealPlanEntity.fromMap(Map<String, dynamic>.from(plan))
          else
            throw ArgumentError(
              'WeekPlanEntity.fromMap: invalid meal plan item: $plan',
            ),
      ],
      startDate: DateTime.fromMillisecondsSinceEpoch(
        _readEpochMsField(m, 'startDate'),
      ),
      endDate: DateTime.fromMillisecondsSinceEpoch(
        _readEpochMsField(m, 'endDate'),
      ),
      fitnessGoal: m['fitnessGoal']?.toString() ?? '',
      dietaryPreferences: m['dietaryPreferences']?.toString() ?? '',
      cuisines: List<String>.from(m['cuisines'] ?? []),
      mealsTypes: List<String>.from(m['mealsTypes'] ?? []),
    );
  }

  /// Сравнение с [startDateMs] из таски/Directus (фильтр не всегда совпадает по типу поля).
  static int? tryParseStartDateEpochMs(Object? row) {
    if (row is! Map) return null;
    try {
      return _readEpochMsField(Map<String, dynamic>.from(row), 'startDate');
    } on Object {
      return null;
    }
  }

  /// Directus/таски: epoch ms [String], [int] или [num].
  static int _readEpochMsField(Map<dynamic, dynamic> map, String key) {
    final v = map[key];
    if (v == null) {
      throw ArgumentError('WeekPlanEntity: missing $key');
    }
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty) {
        throw ArgumentError('WeekPlanEntity: empty $key');
      }
      return int.parse(t);
    }
    return int.parse(v.toString().trim());
  }

  Map<String, dynamic> toMap() {
    final map = {
      'userId': userId,
      'mealPlans': plans.map((plan) => plan.toMap()).toList(),
      'startDate': startDate.millisecondsSinceEpoch.toString(),
      'endDate': endDate.millisecondsSinceEpoch.toString(),
      'fitnessGoal': fitnessGoal,
      'dietaryPreferences': dietaryPreferences,
      'cuisines': cuisines,
      'mealsTypes': mealsTypes,
    };

    // ✅ Отладочные логи для проверки сериализации
    print('[WeekPlanEntity.toMap] Сериализация плана с userId: $userId');
    print('[WeekPlanEntity.toMap] Данные для Directus: ${map.keys.join(', ')}');

    return map;
  }

  String formatPeriod() {
    final yearFormat = DateFormat('yyyy');
    final monthFormat = DateFormat('MMM');
    final dayFormat = DateFormat('d');

    final year = yearFormat.format(startDate);
    final month = monthFormat.format(startDate);
    final startDay = dayFormat.format(startDate);
    final endDay = dayFormat.format(endDate);

    return '$year $month $startDay-$endDay';
  }

  final String userId;
  final List<MealPlanEntity> plans;
  final DateTime startDate;
  final DateTime endDate;
  final String fitnessGoal;
  final String dietaryPreferences;
  final List<String> cuisines;
  final List<String> mealsTypes;

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  @override
  List<Object?> get props => [userId, plans, startDate, endDate];

  WeekPlanEntity copyWith({
    String? userId,
    List<MealPlanEntity>? plans,
    DateTime? startDate,
    DateTime? endDate,
    String? fitnessGoal,
    String? dietaryPreferences,
    List<String>? cuisines,
    List<String>? mealsTypes,
  }) {
    return WeekPlanEntity(
      userId: userId ?? this.userId,
      plans: plans ?? this.plans,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      cuisines: cuisines ?? this.cuisines,
      mealsTypes: mealsTypes ?? this.mealsTypes,
    );
  }
}
