import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rishai/core/services/image_picker/image_picker_helper.dart';
import 'package:rishai/core/services/image_picker/image_picker_service.dart';
import 'package:rishai/features/food_diary/presentation/bloc/food_diary_cubit.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ImagePickerHandler
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Класс для обработки логики выбора изображений из камеры или галереи.
///
/// **Функциональность:**
/// - Показ диалога выбора источника изображения
/// - Обработка выбора одной или нескольких фотографий
/// - Валидация лимита фотографий
/// - Обработка ошибок и разрешений
///
/// **Использование:**
/// Используется в CustomMealItem для инкапсуляции логики работы с изображениями,
/// чтобы уменьшить сложность виджета.
///
class ImagePickerHandler {
  /// Конструктор
  ImagePickerHandler({
    ImagePickerService? imagePickerService,
  }) : _imagePickerService = imagePickerService ?? ImagePickerService() {
    _imagePickerHelper = ImagePickerHelper(_imagePickerService);
  }

  /// Сервис для работы с изображениями
  final ImagePickerService _imagePickerService;

  /// Хелпер для работы с диалогами выбора изображений
  late final ImagePickerHelper _imagePickerHelper;

  /// [pickImages] Выбирает изображения из камеры или галереи
  ///
  /// Показывает диалог выбора источника и обрабатывает результат.
  /// Учитывает лимит на количество фотографий.
  /// Разрешения проверяются и запрашиваются после выбора источника
  /// пользователем (камера или галерея) в ImagePickerHelper.
  ///
  /// **Параметры:**
  /// - context: Контекст для показа диалога
  /// - currentPhotoCount: Текущее количество фотографий (для проверки лимита)
  /// - maxPhotos: Максимальное количество фотографий для данного блюда
  ///
  /// **Возвращает:**
  /// - XFile? если выбрана одна фотография
  /// - List<XFile>? если выбрано несколько фотографий
  /// - null если выбор отменен или произошла ошибка
  ///
  /// **Выбрасывает:**
  /// Exception при ошибке доступа к камере/галерее или разрешениям
  ///
  Future<dynamic> pickImages({
    required BuildContext context,
    required int currentPhotoCount,
    required int maxPhotos,
  }) async {
    // Вычисляем доступные слоты
    final availableSlots = maxPhotos - currentPhotoCount;

    // Проверяем лимит фотографий
    if (availableSlots <= 0) {
      throw Exception('Maximum $maxPhotos photos allowed');
    }

    try {
      // Показываем диалог выбора источника
      // Разрешения будут запрошены в ImagePickerHelper после выбора источника
      final dynamic result =
          await _imagePickerHelper.showAppleStyleImageSourceDialog(
        context: context,
        imageQuality: FoodDiaryCubit.imageQuality,
        maxWidth: FoodDiaryCubit.maxImageWidth,
        maxHeight: FoodDiaryCubit.maxImageHeight,
        allowMultiple: true,
        limit: availableSlots,
      );

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// [handleImageResult] Обрабатывает результат выбора изображений
  ///
  /// Конвертирует результат в список XFile для удобной обработки.
  ///
  /// **Параметры:**
  /// - result: Результат выбора (XFile или List<XFile>)
  ///
  /// **Возвращает:**
  /// List<XFile> с выбранными изображениями
  ///
  /// **Выбрасывает:**
  /// Exception если результат пустой или имеет неожиданный тип
  ///
  List<XFile> handleImageResult(result) {
    if (result is XFile) {
      // Одна фотография
      return [result];
    } else if (result is List<XFile>) {
      // Несколько фотографий
      if (result.isEmpty) {
        throw Exception(
          'Could not load photos. Please make sure they are downloaded from iCloud.',
        );
      }

      return result;
    } else {
      throw Exception('Unexpected result type: ${result.runtimeType}');
    }
  }
}
