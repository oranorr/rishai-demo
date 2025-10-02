// ignore_for_file: public_member_api_docs, sort_constructors_first
class WeekFilterEntity {
  WeekFilterEntity({
    required this.startDate,
    required this.endDate,
    required this.fitnessGoal,
    required this.dietaryPreferences,
    required this.cuisines,
    required this.mealsTypes,
  });
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> fitnessGoal;
  final List<String> dietaryPreferences;
  final List<String> cuisines;
  final List<String> mealsTypes;

  WeekFilterEntity copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? fitnessGoal,
    List<String>? dietaryPreferences,
    List<String>? cuisines,
    List<String>? mealsTypes,
  }) {
    return WeekFilterEntity(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      cuisines: cuisines ?? this.cuisines,
      mealsTypes: mealsTypes ?? this.mealsTypes,
    );
  }

  @override
  String toString() {
    return 'WeekFilterEntity(startDate: $startDate, endDate: $endDate, fitnessGoal: $fitnessGoal, dietaryPreferences: $dietaryPreferences, cuisines: $cuisines, mealsTypes: $mealsTypes)';
  }

  bool get hasActiveFilters {
    final hasDates = startDate != null && endDate != null;
    final hasDiet = dietaryPreferences.isNotEmpty;
    final hasGoal = fitnessGoal.isNotEmpty;
    final hasCuisines = cuisines.isNotEmpty;
    final hasMealsTypes = mealsTypes.isNotEmpty;
    return hasDates || hasDiet || hasGoal || hasCuisines || hasMealsTypes;
  }

  /// Маппинг старых названий фитнес целей на новые
  /// Старые названия: Aesthetics, Performance, Recomp, Optimize me
  /// Новые названия: Fat Loss, Muscle Gain, Body Recomp, Optimize Me
  static String mapOldFitnessGoalToNew(String oldGoal) {
    switch (oldGoal.toLowerCase()) {
      case 'aesthetics':
        return 'Fat Loss';
      case 'performance':
        return 'Muscle Gain';
      case 'recomp':
        return 'Body Recomp';
      case 'optimize':
        return 'Optimize Me';
      case 'optimize me':
        return 'Optimize Me'; // Обработка старого названия с маленькой 'm'
      default:
        return oldGoal; // Возвращаем как есть, если не знаем
    }
  }

  /// Проверяет, соответствует ли план фильтру по фитнес цели
  /// Учитывает как новые, так и старые названия целей
  bool matchesFitnessGoal(String planGoal) {
    if (fitnessGoal.isEmpty) return true; // Если фильтр пустой, пропускаем

    // Нормализуем цель плана (старое название -> новое)
    final normalizedPlanGoal = mapOldFitnessGoalToNew(planGoal);

    // Проверяем соответствие с фильтрами
    return fitnessGoal.any((filterGoal) {
      // Нормализуем цель фильтра (на случай если там тоже есть старые названия)
      final normalizedFilterGoal = mapOldFitnessGoalToNew(filterGoal);

      // Сравниваем нормализованные названия
      return normalizedPlanGoal == normalizedFilterGoal;
    });
  }
}
