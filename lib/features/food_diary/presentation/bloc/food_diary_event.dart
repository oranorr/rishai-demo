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

// ══════════════════════════════════════════════════════════════════════════════
// События для страницы DiaryEntryPage
// ══════════════════════════════════════════════════════════════════════════════

/// [DiaryEntryPageInitialize] Событие инициализации страницы добавления блюд
///
/// Загружает доступные блюда из дневного и недельного планов,
/// фильтрует уже потребленные блюда, подготавливает UI.
class DiaryEntryPageInitialize extends FoodDiaryEvent {
  const DiaryEntryPageInitialize();
}

/// [DiaryEntryToggleMealSelection] Событие переключения выбора блюда
///
/// Добавляет или удаляет блюдо из списка выбранных для добавления в дневник.
class DiaryEntryToggleMealSelection extends FoodDiaryEvent {
  /// Блюдо для переключения выбора
  final Meal meal;

  /// Новое состояние выбора (true = выбрано, false = не выбрано)
  final bool isSelected;

  const DiaryEntryToggleMealSelection({
    required this.meal,
    required this.isSelected,
  });

  @override
  List<Object?> get props => [meal, isSelected];
}

/// [DiaryEntrySetMealType] Событие установки типа приема пищи
///
/// Используется для выбора типа приема пищи (завтрак, обед, ужин, перекус)
/// при добавлении кастомных блюд.
class DiaryEntrySetMealType extends FoodDiaryEvent {
  /// Выбранный тип приема пищи
  final ServingType? mealType;

  const DiaryEntrySetMealType({
    required this.mealType,
  });

  @override
  List<Object?> get props => [mealType];
}

/// [DiaryEntryAddSelectedMeals] Событие добавления выбранных блюд в дневник
///
/// Добавляет все выбранные блюда в дневник питания, рассчитывает wellness score,
/// очищает список выбранных блюд после успешного добавления.
class DiaryEntryAddSelectedMeals extends FoodDiaryEvent {
  const DiaryEntryAddSelectedMeals();
}

/// [DiaryEntryClearSelection] Событие очистки выбранных блюд
///
/// Очищает список выбранных блюд без добавления их в дневник.
/// Используется при отмене или сбросе выбора.
class DiaryEntryClearSelection extends FoodDiaryEvent {
  const DiaryEntryClearSelection();
}

/// [DiaryEntryUpdatePhotos] Событие обновления списка фотографий
///
/// Обновляет список выбранных фотографий блюд.
/// Используется при добавлении или удалении фотографий.
class DiaryEntryUpdatePhotos extends FoodDiaryEvent {
  /// Список фотографий
  final List<XFile> photos;

  const DiaryEntryUpdatePhotos({
    required this.photos,
  });

  @override
  List<Object?> get props => [photos];
}

/// [DiaryEntryAddPhoto] Событие добавления фотографии
///
/// Добавляет новую фотографию в список выбранных фотографий блюда.
class DiaryEntryAddPhoto extends FoodDiaryEvent {
  /// Фотография для добавления
  final XFile photo;

  const DiaryEntryAddPhoto({
    required this.photo,
  });

  @override
  List<Object?> get props => [photo];
}

/// [DiaryEntryAddPhotos] Событие добавления нескольких фотографий
///
/// Добавляет несколько фотографий в список выбранных фотографий блюда.
class DiaryEntryAddPhotos extends FoodDiaryEvent {
  /// Список фотографий для добавления
  final List<XFile> photos;

  const DiaryEntryAddPhotos({
    required this.photos,
  });

  @override
  List<Object?> get props => [photos];
}

/// [DiaryEntryRemovePhoto] Событие удаления фотографии
///
/// Удаляет фотографию из списка выбранных фотографий блюда по индексу.
class DiaryEntryRemovePhoto extends FoodDiaryEvent {
  /// Индекс фотографии для удаления
  final int index;

  const DiaryEntryRemovePhoto({
    required this.index,
  });

  @override
  List<Object?> get props => [index];
}

/// [DiaryEntryUpdateDescription] Событие обновления описания блюда
///
/// Обновляет текстовое описание кастомного блюда.
/// @deprecated Используйте CustomMealUpdateDescription с указанием mealId
class DiaryEntryUpdateDescription extends FoodDiaryEvent {
  /// Описание блюда
  final String description;

  const DiaryEntryUpdateDescription({
    required this.description,
  });

  @override
  List<Object?> get props => [description];
}

// ══════════════════════════════════════════════════════════════════════════════
// События для управления массивом кастомных блюд
// ══════════════════════════════════════════════════════════════════════════════

/// [CustomMealAdd] Событие добавления нового кастомного блюда
///
/// Добавляет новое пустое блюдо в массив customMeals.
/// Используется при нажатии на кнопку "Add more".
class CustomMealAdd extends FoodDiaryEvent {
  const CustomMealAdd();
}

/// [CustomMealRemove] Событие удаления кастомного блюда
///
/// Удаляет блюдо из массива по его ID.
/// Используется при нажатии на кнопку удаления (X) на карточке блюда.
class CustomMealRemove extends FoodDiaryEvent {
  /// ID блюда для удаления
  final String mealId;

  const CustomMealRemove({
    required this.mealId,
  });

  @override
  List<Object?> get props => [mealId];
}

/// [CustomMealUpdatePhotos] Событие обновления фотографий блюда
///
/// Обновляет список фотографий для конкретного блюда.
class CustomMealUpdatePhotos extends FoodDiaryEvent {
  /// ID блюда
  final String mealId;

  /// Новый список фотографий
  final List<XFile> photos;

  const CustomMealUpdatePhotos({
    required this.mealId,
    required this.photos,
  });

  @override
  List<Object?> get props => [mealId, photos];
}

/// [CustomMealAddPhoto] Событие добавления фотографии к блюду
///
/// Добавляет одну фотографию к существующему списку фотографий блюда.
class CustomMealAddPhoto extends FoodDiaryEvent {
  /// ID блюда
  final String mealId;

  /// Фотография для добавления
  final XFile photo;

  const CustomMealAddPhoto({
    required this.mealId,
    required this.photo,
  });

  @override
  List<Object?> get props => [mealId, photo];
}

/// [CustomMealAddPhotos] Событие добавления нескольких фотографий к блюду
///
/// Добавляет несколько фотографий к существующему списку фотографий блюда.
class CustomMealAddPhotos extends FoodDiaryEvent {
  /// ID блюда
  final String mealId;

  /// Список фотографий для добавления
  final List<XFile> photos;

  const CustomMealAddPhotos({
    required this.mealId,
    required this.photos,
  });

  @override
  List<Object?> get props => [mealId, photos];
}

/// [CustomMealRemovePhoto] Событие удаления фотографии из блюда
///
/// Удаляет фотографию по индексу из списка фотографий блюда.
class CustomMealRemovePhoto extends FoodDiaryEvent {
  /// ID блюда
  final String mealId;

  /// Индекс фотографии для удаления
  final int photoIndex;

  const CustomMealRemovePhoto({
    required this.mealId,
    required this.photoIndex,
  });

  @override
  List<Object?> get props => [mealId, photoIndex];
}

/// [CustomMealUpdateDescription] Событие обновления описания блюда
///
/// Обновляет текстовое описание конкретного блюда.
class CustomMealUpdateDescription extends FoodDiaryEvent {
  /// ID блюда
  final String mealId;

  /// Новое описание
  final String description;

  const CustomMealUpdateDescription({
    required this.mealId,
    required this.description,
  });

  @override
  List<Object?> get props => [mealId, description];
}

/// [CustomMealSetMealType] Событие установки типа приема пищи для блюда
///
/// Устанавливает тип приема пищи для конкретного блюда.
class CustomMealSetMealType extends FoodDiaryEvent {
  /// ID блюда
  final String mealId;

  /// Тип приема пищи
  final ServingType? mealType;

  const CustomMealSetMealType({
    required this.mealId,
    required this.mealType,
  });

  @override
  List<Object?> get props => [mealId, mealType];
}

/// [CustomMealSetAnalyzedResult] Событие сохранения результата анализа блюда
///
/// Сохраняет результат анализа фотографии блюда от сервера.
/// После получения ответа от сервера, блюдо переходит в режим read-only
/// и отображает полученные данные (название, макросы).
class CustomMealSetAnalyzedResult extends FoodDiaryEvent {
  /// ID блюда
  final String mealId;

  /// Результат анализа от сервера
  final DiaryMeal analyzedMeal;

  const CustomMealSetAnalyzedResult({
    required this.mealId,
    required this.analyzedMeal,
  });

  @override
  List<Object?> get props => [mealId, analyzedMeal];
}

/// [CustomMealReset] Событие сброса блюда в пустое состояние
///
/// Заменяет блюдо на пустую карточку, сохраняя тот же ID.
/// Используется при удалении единственного проанализированного блюда.
class CustomMealReset extends FoodDiaryEvent {
  /// ID блюда для сброса
  final String mealId;

  const CustomMealReset({
    required this.mealId,
  });

  @override
  List<Object?> get props => [mealId];
}

/// [CustomMealToggleSelection] Событие переключения выбора проанализированного блюда
///
/// Добавляет или убирает проанализированное блюдо из списка выбранных
/// для добавления в дневник.
class CustomMealToggleSelection extends FoodDiaryEvent {
  /// ID блюда
  final String mealId;

  const CustomMealToggleSelection({
    required this.mealId,
  });

  @override
  List<Object?> get props => [mealId];
}

/// [CustomMealStartRegenerating] Событие начала регенерации анализа блюда
///
/// Отмечает блюдо как регенерирующееся, чтобы заблокировать кнопку добавления
/// в дневник во время процесса регенерации.
class CustomMealStartRegenerating extends FoodDiaryEvent {
  /// ID блюда, которое регенерируется
  final String mealId;

  const CustomMealStartRegenerating({
    required this.mealId,
  });

  @override
  List<Object?> get props => [mealId];
}

/// [CustomMealStopRegenerating] Событие окончания регенерации анализа блюда
///
/// Убирает блюдо из списка регенерирующихся, разблокируя кнопку добавления
/// в дневник после завершения процесса регенерации.
class CustomMealStopRegenerating extends FoodDiaryEvent {
  /// ID блюда, которое завершило регенерацию
  final String mealId;

  const CustomMealStopRegenerating({
    required this.mealId,
  });

  @override
  List<Object?> get props => [mealId];
}
