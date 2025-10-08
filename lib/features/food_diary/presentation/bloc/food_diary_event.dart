// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'food_diary_cubit.dart';

/// [FoodDiaryEvent] Базовый класс для всех событий дневника питания
sealed class FoodDiaryEvent extends Equatable {
  const FoodDiaryEvent();

  @override
  List<Object?> get props => [];
}

/// [FoodDiaryInitialize] Событие инициализации дневника питания
///
/// Запускается при первом открытии дневника или при необходимости
/// перезагрузки данных
class FoodDiaryInitialize extends FoodDiaryEvent {
  const FoodDiaryInitialize();
}

/// [FoodDiaryAddEntry] Событие добавления новой записи в дневник
///
/// Используется для добавления информации о потребленной пище
class FoodDiaryAddEntry extends FoodDiaryEvent {
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

  const FoodDiaryAddEntry({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.weight,
    required this.timestamp,
    required this.mealType,
  });

  @override
  List<Object?> get props => [
        foodName,
        calories,
        protein,
        carbs,
        fat,
        weight,
        timestamp,
        mealType,
      ];
}

/// [FoodDiaryUpdateEntry] Событие обновления существующей записи
///
/// Используется для изменения информации о ранее добавленной пище
class FoodDiaryUpdateEntry extends FoodDiaryEvent {
  /// ID записи для обновления
  final String entryId;

  /// Новое название продукта или блюда
  final String? foodName;

  /// Новое количество калорий
  final double? calories;

  /// Новое количество белков в граммах
  final double? protein;

  /// Новое количество углеводов в граммах
  final double? carbs;

  /// Новое количество жиров в граммах
  final double? fat;

  /// Новый вес порции в граммах
  final double? weight;

  /// Новое время приема пищи
  final DateTime? timestamp;

  /// Новый тип приема пищи
  final String? mealType;

  const FoodDiaryUpdateEntry({
    required this.entryId,
    this.foodName,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.weight,
    this.timestamp,
    this.mealType,
  });

  @override
  List<Object?> get props => [
        entryId,
        foodName,
        calories,
        protein,
        carbs,
        fat,
        weight,
        timestamp,
        mealType,
      ];
}

/// [FoodDiaryDeleteEntry] Событие удаления записи из дневника
///
/// Используется для удаления информации о ранее добавленной пище
class FoodDiaryDeleteEntry extends FoodDiaryEvent {
  /// ID записи для удаления
  final String entryId;

  const FoodDiaryDeleteEntry({
    required this.entryId,
  });

  @override
  List<Object?> get props => [entryId];
}

/// [FoodDiaryLoadEntries] Событие загрузки записей дневника
///
/// Используется для загрузки записей за определенную дату или период
class FoodDiaryLoadEntries extends FoodDiaryEvent {
  /// Дата для загрузки записей (опционально)
  /// Если не указана, загружаются записи за текущий день
  final DateTime? date;

  /// Начальная дата для загрузки диапазона (опционально)
  final DateTime? startDate;

  /// Конечная дата для загрузки диапазона (опционально)
  final DateTime? endDate;

  const FoodDiaryLoadEntries({
    this.date,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [date, startDate, endDate];
}

/// [FoodDiaryClearAll] Событие очистки всех записей дневника
///
/// Используется для полной очистки дневника питания
/// ВНИМАНИЕ: Это действие необратимо!
class FoodDiaryClearAll extends FoodDiaryEvent {
  /// Подтверждение очистки (для безопасности)
  final bool confirmed;

  const FoodDiaryClearAll({
    required this.confirmed,
  });

  @override
  List<Object?> get props => [confirmed];
}

/// [FoodDiaryClearTodayEntries] Дебажное событие для очистки записей дневника за сегодня
///
/// Используется для очистки всех записей дневника питания за текущий день.
/// Очищает данные как локально (Hive), так и в Directus.
/// ВНИМАНИЕ: Это дебажная функция, используйте осторожно!
class FoodDiaryClearTodayEntries extends FoodDiaryEvent {
  /// Подтверждение очистки (для безопасности)
  final bool confirmed;

  const FoodDiaryClearTodayEntries({
    this.confirmed = true,
  });

  @override
  List<Object?> get props => [confirmed];
}
