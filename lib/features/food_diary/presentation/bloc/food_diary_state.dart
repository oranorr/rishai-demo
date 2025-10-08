// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'food_diary_cubit.dart';

/// [FoodDiaryEntry] Модель записи в дневнике питания
///
/// Представляет одну запись о потребленной пище с полной информацией
/// о пищевой ценности и времени приема
class FoodDiaryEntry extends Equatable {
  /// Уникальный идентификатор записи
  final String id;

  /// Название продукта или блюда
  final String foodName;

  /// Количество калорий
  final double calories;

  /// Количество белков в граммах
  final double protein;

  /// Количество углеводов в граммах
  final double carbs;

  /// Количество жиров в граммах
  final double fat;

  /// Вес порции в граммах
  final double weight;

  /// Время приема пищи
  final DateTime timestamp;

  /// Тип приема пищи (завтрак, обед, ужин, перекус)
  final String mealType;

  /// Дата создания записи
  final DateTime createdAt;

  /// Дата последнего обновления записи
  final DateTime updatedAt;

  const FoodDiaryEntry({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.weight,
    required this.timestamp,
    required this.mealType,
    required this.createdAt,
    required this.updatedAt,
  });

  /// [copyWith] Создает копию записи с возможностью изменения отдельных полей
  FoodDiaryEntry copyWith({
    String? id,
    String? foodName,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? weight,
    DateTime? timestamp,
    String? mealType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodDiaryEntry(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      weight: weight ?? this.weight,
      timestamp: timestamp ?? this.timestamp,
      mealType: mealType ?? this.mealType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        foodName,
        calories,
        protein,
        carbs,
        fat,
        weight,
        timestamp,
        mealType,
        createdAt,
        updatedAt,
      ];
}

/// [FoodDiaryState] Базовое состояние дневника питания
sealed class FoodDiaryState extends Equatable {
  const FoodDiaryState();

  @override
  List<Object?> get props => [];
}

/// [FoodDiaryMainState] Основное состояние дневника питания
///
/// Содержит все данные о записях в дневнике и общую статистику
class FoodDiaryMainState extends FoodDiaryState {
  /// Текущий статус операций (загрузка, успех, ошибка)
  final Status status;

  /// Список всех записей в дневнике
  final List<FoodDiaryEntry> entries;

  /// Общее количество потребленных калорий
  final double totalCalories;

  /// Общее количество потребленных белков в граммах
  final double totalProtein;

  /// Общее количество потребленных углеводов в граммах
  final double totalCarbs;

  /// Общее количество потребленных жиров в граммах
  final double totalFat;

  /// Дата, за которую отображаются записи
  final DateTime? selectedDate;

  /// Сообщение об ошибке (если есть)
  final String? errorMessage;

  const FoodDiaryMainState({
    required this.status,
    required this.entries,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.selectedDate,
    this.errorMessage,
  });

  /// [copyWith] Создает копию состояния с возможностью изменения отдельных полей
  FoodDiaryMainState copyWith({
    Status? status,
    List<FoodDiaryEntry>? entries,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    DateTime? selectedDate,
    String? errorMessage,
  }) {
    return FoodDiaryMainState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// [entriesByMealType] Возвращает записи, сгруппированные по типу приема пищи
  Map<String, List<FoodDiaryEntry>> get entriesByMealType {
    final Map<String, List<FoodDiaryEntry>> grouped = {};

    for (final entry in entries) {
      if (!grouped.containsKey(entry.mealType)) {
        grouped[entry.mealType] = [];
      }
      grouped[entry.mealType]!.add(entry);
    }

    return grouped;
  }

  /// [caloriesByMealType] Возвращает калории, сгруппированные по типу приема пищи
  Map<String, double> get caloriesByMealType {
    final Map<String, double> grouped = {};

    for (final entry in entries) {
      grouped[entry.mealType] = (grouped[entry.mealType] ?? 0) + entry.calories;
    }

    return grouped;
  }

  /// [hasEntries] Проверяет, есть ли записи в дневнике
  bool get hasEntries => entries.isNotEmpty;

  /// [isLoading] Проверяет, выполняется ли загрузка
  bool get isLoading => status == Status.loading;

  /// [hasError] Проверяет, есть ли ошибка
  bool get hasError => status == Status.error;

  /// [isSuccess] Проверяет, успешно ли выполнена операция
  bool get isSuccess => status == Status.success;

  @override
  List<Object?> get props => [
        status,
        entries,
        totalCalories,
        totalProtein,
        totalCarbs,
        totalFat,
        selectedDate,
        errorMessage,
      ];
}
