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

/// [DiaryEntryPageState] Состояние страницы добавления блюд в дневник
///
/// Содержит данные для UI страницы выбора и добавления блюд:
/// - Список доступных блюд из планов (дневного и недельного)
/// - Список выбранных пользователем блюд
/// - Массив кастомных блюд для создания пользователем
/// - Статус загрузки/обработки
///
/// **LEGACY поля (deprecated, будут удалены):**
/// - selectedMealType, selectedPhotos, mealDescription - заменены на customMeals
class DiaryEntryPageState extends FoodDiaryState {
  /// Текущий статус операций (загрузка, успех, ошибка)
  final Status status;

  /// Список доступных блюд для выбора (из дневного и недельного планов, исключая уже потребленные)
  final List<Meal> availableMeals;

  /// Список выбранных пользователем блюд для добавления в дневник
  final List<Meal> selectedMeals;

  /// Массив кастомных блюд, создаваемых пользователем
  /// По умолчанию содержит одно пустое блюдо
  final List<CustomMealEntry> customMeals;

  /// [LEGACY] Выбранный тип приема пищи для кастомных блюд
  /// @deprecated Используйте customMeals[index].mealType
  final ServingType? selectedMealType;

  /// [LEGACY] Список выбранных фотографий блюд
  /// @deprecated Используйте customMeals[index].photos
  final List<XFile> selectedPhotos;

  /// [LEGACY] Описание кастомного блюда
  /// @deprecated Используйте customMeals[index].description
  final String mealDescription;

  /// Сообщение об ошибке (если есть)
  final String? errorMessage;

  const DiaryEntryPageState({
    required this.status,
    required this.availableMeals,
    required this.selectedMeals,
    required this.customMeals,
    required this.selectedPhotos,
    required this.mealDescription,
    this.selectedMealType,
    this.errorMessage,
  });

  /// [DiaryEntryPageState.initial] Начальное состояние страницы
  factory DiaryEntryPageState.initial() {
    return DiaryEntryPageState(
      status: Status.initial,
      availableMeals: const [],
      selectedMeals: const [],
      customMeals: [CustomMealEntry.empty()], // Начинаем с одного пустого блюда
      selectedPhotos: const [],
      mealDescription: '',
    );
  }

  /// [copyWith] Создает копию состояния с возможностью изменения отдельных полей
  DiaryEntryPageState copyWith({
    Status? status,
    List<Meal>? availableMeals,
    List<Meal>? selectedMeals,
    List<CustomMealEntry>? customMeals,
    ServingType? selectedMealType,
    List<XFile>? selectedPhotos,
    String? mealDescription,
    String? errorMessage,
    bool clearMealType = false,
  }) {
    return DiaryEntryPageState(
      status: status ?? this.status,
      availableMeals: availableMeals ?? this.availableMeals,
      selectedMeals: selectedMeals ?? this.selectedMeals,
      customMeals: customMeals ?? this.customMeals,
      selectedMealType:
          clearMealType ? null : (selectedMealType ?? this.selectedMealType),
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      mealDescription: mealDescription ?? this.mealDescription,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// [isLoading] Проверяет, выполняется ли загрузка
  bool get isLoading => status == Status.loading;

  /// [hasError] Проверяет, есть ли ошибка
  bool get hasError => status == Status.error;

  /// [isSuccess] Проверяет, успешно ли выполнена операция
  bool get isSuccess => status == Status.success;

  /// [hasSelectedMeals] Проверяет, есть ли выбранные блюда
  bool get hasSelectedMeals => selectedMeals.isNotEmpty;

  /// [selectedMealsCount] Возвращает количество выбранных блюд
  int get selectedMealsCount => selectedMeals.length;

  /// [selectedCustomMeals] Возвращает список выбранных кастомных проанализированных блюд
  ///
  /// Содержит только те блюда, которые:
  /// - Проанализированы (isAnalyzed = true)
  /// - Выбраны пользователем (isSelected = true)
  List<CustomMealEntry> get selectedCustomMeals {
    return customMeals
        .where((meal) => meal.isAnalyzed && meal.isSelected)
        .toList();
  }

  /// [selectedCustomMealsCount] Возвращает количество выбранных кастомных блюд
  int get selectedCustomMealsCount {
    return selectedCustomMeals.length;
  }

  @override
  List<Object?> get props => [
        status,
        availableMeals,
        selectedMeals,
        customMeals,
        selectedMealType,
        selectedPhotos,
        mealDescription,
        errorMessage,
      ];
}
