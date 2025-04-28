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
}
