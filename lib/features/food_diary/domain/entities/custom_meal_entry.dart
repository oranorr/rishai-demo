import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rishai/features/chat/data/remote_data_source/llm_proxy_client.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/food_diary/domain/diary_meal.dart';
import 'package:uuid/uuid.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CustomMealEntry Entity
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Представляет одно кастомное блюдо, которое пользователь создает.
///
/// **Поля:**
/// - id: Уникальный идентификатор записи
/// - photos: Список фотографий блюда (до 3)
/// - description: Текстовое описание блюда
/// - mealType: Тип приема пищи (завтрак, обед, ужин, перекус)
/// - analyzedMeal: Результат анализа от сервера (после отправки)
///
/// **Использование:**
/// Используется для хранения данных о кастомном блюде перед отправкой на анализ.
/// Позволяет пользователю создавать несколько блюд одновременно.
/// После получения результата от сервера сохраняет его в analyzedMeal.
///
class CustomMealEntry extends Equatable {
  /// Уникальный идентификатор записи
  final String id;

  /// Список выбранных фотографий блюда
  final List<XFile> photos;

  /// Текстовое описание блюда
  final String description;

  /// Выбранный тип приема пищи
  final ServingType? mealType;

  /// Результат анализа от сервера (null = еще не проанализировано)
  final DiaryMeal? analyzedMeal;

  /// Выбрано ли это блюдо для добавления в дневник (только для проанализированных блюд)
  final bool isSelected;

  const CustomMealEntry({
    required this.id,
    required this.photos,
    required this.description,
    this.mealType,
    this.analyzedMeal,
    this.isSelected = false,
  });

  /// [CustomMealEntry.empty] Создает пустую запись с новым ID
  factory CustomMealEntry.empty() {
    return CustomMealEntry(
      id: const Uuid().v4(),
      photos: const [],
      description: '',
      mealType: null,
      analyzedMeal: null,
      isSelected: false,
    );
  }

  /// [copyWith] Создает копию с возможностью изменения отдельных полей
  CustomMealEntry copyWith({
    String? id,
    List<XFile>? photos,
    String? description,
    ServingType? mealType,
    DiaryMeal? analyzedMeal,
    bool? isSelected,
    bool clearMealType = false,
    bool clearAnalyzedMeal = false,
  }) {
    return CustomMealEntry(
      id: id ?? this.id,
      photos: photos ?? this.photos,
      description: description ?? this.description,
      mealType: clearMealType ? null : (mealType ?? this.mealType),
      analyzedMeal:
          clearAnalyzedMeal ? null : (analyzedMeal ?? this.analyzedMeal),
      isSelected: isSelected != null ? isSelected : this.isSelected,
    );
  }

  /// [isEmpty] Проверяет, пустая ли запись (нет фото и описания)
  bool get isEmpty => photos.isEmpty && description.isEmpty;

  /// [isValid] Проверяет, валидна ли запись для отправки (есть хотя бы 1 фото)
  bool get isValid => photos.isNotEmpty;

  /// [hasPhotos] Проверяет, есть ли фотографии
  bool get hasPhotos => photos.isNotEmpty;

  /// [hasDescription] Проверяет, есть ли описание
  bool get hasDescription => description.isNotEmpty;

  /// [hasMealType] Проверяет, выбран ли тип приема пищи
  bool get hasMealType => mealType != null;

  /// [isAnalyzed] Проверяет, проанализировано ли блюдо сервером
  bool get isAnalyzed => analyzedMeal != null;

  @override
  List<Object?> get props =>
      [id, photos, description, mealType, analyzedMeal, isSelected];

  @override
  String toString() {
    return 'CustomMealEntry(id: $id, photos: ${photos.length}, description: $description, mealType: $mealType, isAnalyzed: $isAnalyzed, isSelected: $isSelected)';
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Конвертер для создания DiaryMeal из ответа сервера
/// ═══════════════════════════════════════════════════════════════════════════

/// [createDiaryMealFromResponse] Создает DiaryMeal из ответа анализа фотографий
///
/// Конвертирует ответ от сервера (FoodPhotoAnalysisResponse) в сущность DiaryMeal,
/// которая используется в дневнике питания.
///
/// **Параметры:**
/// - response: Ответ от сервера с названием блюда и макросами
/// - mealType: Тип приема пищи (если null, используется 'snack')
///
/// **Возвращает:**
/// DiaryMeal с данными из ответа сервера
///
/// **Маппинг полей:**
/// - title = response.nameOfMeal
/// - type = mealType?.name ?? 'snack'
/// - macros.kcal = response.macrosBreakdown.kcals (внимание: kcalS → kcal)
/// - macros.protein = response.macrosBreakdown.protein
/// - macros.carbs = response.macrosBreakdown.carbs
/// - macros.fat = response.macrosBreakdown.fats (внимание: fatS → fat)
/// - isGeneratedMeal = false (это кастомное блюдо пользователя)
///
DiaryMeal createDiaryMealFromResponse(
  FoodPhotoAnalysisResponse response,
  ServingType? mealType,
) {
  print(
    '[createDiaryMealFromResponse] Конвертация ответа сервера в DiaryMeal: ${response.nameOfMeal}',
  );

  // Создаем MacrosBreakdown из DTO
  // Внимание: сервер использует 'fats' и 'kcals', а entity - 'fat' и 'kcal'
  final macros = MacrosBreakdown(
    kcal: response.macrosBreakdown.kcals,
    protein: response.macrosBreakdown.protein,
    carbs: response.macrosBreakdown.carbs,
    fat: response.macrosBreakdown.fats,
  );

  print(
    '[createDiaryMealFromResponse] Макросы: K=${macros.kcal}ккал, P=${macros.protein}г, C=${macros.carbs}г, F=${macros.fat}г',
  );

  // Создаем DiaryMeal
  final diaryMeal = DiaryMeal(
    title: response.nameOfMeal,
    type: mealType?.name ?? 'snack',
    macros: macros,
    isGeneratedMeal: false, // Это кастомное блюдо пользователя
  );

  print(
    '[createDiaryMealFromResponse] ✅ DiaryMeal создан: ${diaryMeal.title} (${diaryMeal.type})',
  );

  return diaryMeal;
}

