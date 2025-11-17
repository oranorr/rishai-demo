import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Сервис для работы с выбором изображений и камерой
///
/// Предоставляет методы для:
/// - Выбора одного изображения из галереи
/// - Выбора нескольких изображений/видео из галереи
/// - Съёмки фото с камеры
/// - Съёмки видео с камеры
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Выбирает одно изображение из галереи
  ///
  /// Параметры:
  /// - [maxWidth] - не используется (убрано для совместимости с iCloud)
  /// - [maxHeight] - не используется (убрано для совместимости с iCloud)
  /// - [imageQuality] - не используется (убрано для совместимости с iCloud)
  ///
  /// Возвращает [XFile?] - выбранное изображение или null, если отменено
  Future<XFile?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      print(
        '[ImagePickerService.pickImageFromGallery] Запрос на выбор изображения',
      );

      // Загружаем без ограничений для лучшей совместимости с iCloud
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        print(
          '[ImagePickerService.pickImageFromGallery] Изображение выбрано: ${image.path}',
        );
      } else {
        print('[ImagePickerService.pickImageFromGallery] Выбор отменен');
      }

      return image;
    } catch (e) {
      print('[ImagePickerService.pickImageFromGallery] Ошибка: $e');
      return null;
    }
  }

  /// Делает фото с помощью камеры
  ///
  /// Параметры:
  /// - [maxWidth] - не используется (убрано для совместимости)
  /// - [maxHeight] - не используется (убрано для совместимости)
  /// - [imageQuality] - не используется (убрано для совместимости)
  /// - [preferredCameraDevice] - предпочитаемая камера (front/rear)
  ///
  /// Возвращает [XFile?] - сделанное фото или null, если отменено
  Future<XFile?> takePhoto({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      print('[ImagePickerService.takePhoto] Запрос на съемку фото');

      // Снимаем без ограничений для лучшей совместимости
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredCameraDevice,
      );

      if (photo != null) {
        print('[ImagePickerService.takePhoto] Фото сделано: ${photo.path}');
      } else {
        print('[ImagePickerService.takePhoto] Съемка отменена');
      }

      return photo;
    } catch (e) {
      print('[ImagePickerService.takePhoto] Ошибка: $e');
      return null;
    }
  }

  /// Выбирает несколько изображений из галереи
  ///
  /// Параметры:
  /// - [maxWidth] - не используется (убрано для совместимости с iCloud)
  /// - [maxHeight] - не используется (убрано для совместимости с iCloud)
  /// - [imageQuality] - не используется (убрано для совместимости с iCloud)
  /// - [limit] - максимальное количество изображений (только для iOS 14+)
  ///
  /// Возвращает [List<XFile>] - список выбранных изображений (пустой, если отменено)
  Future<List<XFile>> pickMultipleImages({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      print(
        '[ImagePickerService.pickMultipleImages] Запрос на выбор изображений (limit: $limit)',
      );

      // [validateLimit] pickMultiImage не принимает limit: 1 (минимум 2)
      // Если limit == 1, не передаем его в pickMultiImage
      // Это защита на случай, если метод вызван напрямую с limit: 1
      final int? validLimit = (limit != null && limit > 1) ? limit : null;

      // Загружаем изображения БЕЗ всех ограничений для максимальной совместимости с iCloud
      // Параметры maxWidth, maxHeight, imageQuality и requestFullMetadata могут вызывать
      // ошибки "Cannot load representation" для изображений в iCloud
      final List<XFile> images = await _picker.pickMultiImage(
        limit: validLimit,
      );

      print(
        '[ImagePickerService.pickMultipleImages] Выбрано изображений: ${images.length}',
      );

      // Валидируем каждое изображение
      final List<XFile> validImages = [];
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        try {
          // Проверяем, что файл существует и можно прочитать его размер
          final file = File(image.path);
          if (await file.exists()) {
            final size = await file.length();
            print(
              '[ImagePickerService.pickMultipleImages] Изображение ${i + 1}/${images.length} (${image.name}): $size bytes',
            );

            // Проверяем размер (не больше 50MB)
            if (size > 0 && size < 50 * 1024 * 1024) {
              validImages.add(image);
            } else {
              print(
                '[ImagePickerService.pickMultipleImages] Пропуск ${image.name}: некорректный размер ($size bytes)',
              );
            }
          } else {
            print(
              '[ImagePickerService.pickMultipleImages] Пропуск ${image.name}: файл не существует',
            );
          }
        } catch (e) {
          print(
            '[ImagePickerService.pickMultipleImages] Ошибка валидации ${image.name}: $e',
          );
          // Пропускаем проблемное изображение, но продолжаем обработку остальных
        }
      }

      print(
        '[ImagePickerService.pickMultipleImages] Валидных изображений: ${validImages.length}',
      );
      
      // [enforceLimit] На Android параметр limit не работает в системном picker'е,
      // поэтому нужно обрезать список после выбора
      // На iOS limit работает только для iOS 14+, на старых версиях тоже нужно обрезать
      if (limit != null && validImages.length > limit) {
        print(
          '[ImagePickerService.pickMultipleImages] ⚠️ Выбрано ${validImages.length} фото, но лимит: $limit. Обрезаем до лимита.',
        );
        return validImages.take(limit).toList();
      }
      
      return validImages;
    } catch (e, stackTrace) {
      print('[ImagePickerService.pickMultipleImages] Критическая ошибка: $e');
      print('[ImagePickerService.pickMultipleImages] StackTrace: $stackTrace');
      return [];
    }
  }

  /// Выбирает несколько медиафайлов (изображения и видео) из галереи
  ///
  /// Параметры:
  /// - [imageQuality] - не используется (убрано для совместимости с iCloud)
  /// - [limit] - максимальное количество файлов (только для iOS 14+)
  ///
  /// Возвращает [List<XFile>] - список выбранных медиафайлов (пустой, если отменено)
  Future<List<XFile>> pickMultipleMedia({
    int? imageQuality,
    int? limit,
  }) async {
    try {
      print(
        '[ImagePickerService.pickMultipleMedia] Запрос на выбор медиафайлов (limit: $limit)',
      );

      // Загружаем БЕЗ ограничений для совместимости с iCloud
      final List<XFile> media = await _picker.pickMultipleMedia(
        limit: limit,
      );

      print(
        '[ImagePickerService.pickMultipleMedia] Выбрано медиафайлов: ${media.length}',
      );
      return media;
    } catch (e) {
      print('[ImagePickerService.pickMultipleMedia] Ошибка: $e');
      return [];
    }
  }

  /// Записывает видео с помощью камеры
  ///
  /// Параметры:
  /// - [maxDuration] - максимальная длительность видео
  /// - [preferredCameraDevice] - предпочитаемая камера (front/rear)
  ///
  /// Возвращает [XFile?] - записанное видео или null, если отменено
  Future<XFile?> recordVideo({
    Duration? maxDuration,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration,
        preferredCameraDevice: preferredCameraDevice,
      );
      return video;
    } catch (e) {
      print('[ImagePickerService.recordVideo] Error: $e');
      return null;
    }
  }

  /// Выбирает видео из галереи
  ///
  /// Параметры:
  /// - [maxDuration] - максимальная длительность видео
  ///
  /// Возвращает [XFile?] - выбранное видео или null, если отменено
  Future<XFile?> pickVideoFromGallery({
    Duration? maxDuration,
  }) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxDuration,
      );
      return video;
    } catch (e) {
      print('[ImagePickerService.pickVideoFromGallery] Error: $e');
      return null;
    }
  }

  /// Конвертирует XFile в File
  ///
  /// Параметры:
  /// - [xFile] - файл XFile для конвертации
  ///
  /// Возвращает [File] - объект File
  File xFileToFile(XFile xFile) {
    return File(xFile.path);
  }

  /// Конвертирует список XFile в список File
  ///
  /// Параметры:
  /// - [xFiles] - список файлов XFile для конвертации
  ///
  /// Возвращает [List<File>] - список объектов File
  List<File> xFilesToFiles(List<XFile> xFiles) {
    return xFiles.map((xFile) => File(xFile.path)).toList();
  }

  /// Проверяет, является ли файл изображением
  ///
  /// Параметры:
  /// - [file] - файл для проверки
  ///
  /// Возвращает [bool] - true, если файл является изображением
  bool isImage(XFile file) {
    final List<String> imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
    ];
    return imageExtensions.any(
      (ext) => file.path.toLowerCase().endsWith(ext),
    );
  }

  /// Проверяет, является ли файл видео
  ///
  /// Параметры:
  /// - [file] - файл для проверки
  ///
  /// Возвращает [bool] - true, если файл является видео
  bool isVideo(XFile file) {
    final List<String> videoExtensions = [
      '.mp4',
      '.mov',
      '.avi',
      '.mkv',
      '.webm',
    ];
    return videoExtensions.any(
      (ext) => file.path.toLowerCase().endsWith(ext),
    );
  }
}
