import 'package:image_picker/image_picker.dart';
import 'package:rishai/core/di/injectable.dart';
import 'package:rishai/features/chat/data/remote_data_source/llm_proxy_client.dart';
import 'package:rishai/features/food_diary/domain/entities/custom_meal_entry.dart'
    show createDiaryMealFromResponse;
import 'package:rishai/features/food_diary/domain/diary_meal.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MealAnalysisHandler
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Класс для обработки логики анализа блюд через LLM прокси.
///
/// **Функциональность:**
/// - Отправка запроса на анализ фотографий
/// - Регенерация анализа с теми же данными
/// - Конвертация ответа сервера в DiaryMeal
/// - Обработка ошибок
///
/// **Использование:**
/// Используется в CustomMealItem для инкапсуляции логики анализа,
/// чтобы уменьшить сложность виджета.
///
class MealAnalysisHandler {
  /// Конструктор с инъекцией зависимостей
  MealAnalysisHandler({
    LlmProxyClient? llmProxyClient,
  }) : _llmProxyClient = llmProxyClient ?? getIt.get<LlmProxyClient>();

  /// Клиент для работы с LLM прокси
  final LlmProxyClient _llmProxyClient;

  /// [analyzeMeal] Анализирует блюдо по фотографиям и описанию
  ///
  /// Отправляет запрос на анализ фотографий и возвращает результат
  /// в виде DiaryMeal.
  ///
  /// **Параметры:**
  /// - photos: Список фотографий блюда (опционально, может быть пустым)
  /// - description: Текстовое описание блюда
  /// - mealType: Тип приема пищи для сохранения в результате
  ///
  /// **Возвращает:**
  /// DiaryMeal с результатами анализа
  ///
  /// **Выбрасывает:**
  /// Exception при ошибке запроса или обработки ответа
  ///
  Future<DiaryMeal> analyzeMeal({
    required List<XFile> photos,
    required String description,
    required mealType,
  }) async {
    // Фотографии опциональны - можно передавать пустой массив
    // Анализ будет проводиться только на основе текстового описания

    try {
      // Отправляем запрос на анализ
      final result = await _llmProxyClient.analyzeFoodPhoto(
        images: photos,
        description: description,
      );

      // Конвертируем ответ сервера в DiaryMeal
      final diaryMeal = createDiaryMealFromResponse(result, mealType);

      return diaryMeal;
    } catch (e) {
      rethrow;
    }
  }

  /// [regenerateAnalysis] Регенерирует анализ для уже проанализированного блюда
  ///
  /// Повторяет запрос анализа с теми же данными (фото и описание).
  /// Используется когда пользователь хочет получить другой результат анализа.
  ///
  /// **Параметры:**
  /// - photos: Список фотографий блюда (опционально, может быть пустым)
  /// - description: Текстовое описание блюда
  /// - mealType: Тип приема пищи
  ///
  /// **Возвращает:**
  /// Новый DiaryMeal с результатами регенерации
  ///
  /// **Выбрасывает:**
  /// Exception при ошибке запроса
  ///
  Future<DiaryMeal> regenerateAnalysis({
    required List<XFile> photos,
    required String description,
    required mealType,
  }) async {
    // Фотографии опциональны - можно передавать пустой массив
    // Используем тот же метод анализа
    return analyzeMeal(
      photos: photos,
      description: description,
      mealType: mealType,
    );
  }
}
