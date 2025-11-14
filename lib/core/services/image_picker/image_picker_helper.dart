import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rishai/core/services/image_picker/image_picker_service.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/dialog.dart';

/// Вспомогательный класс для отображения диалогов выбора источника изображения
class ImagePickerHelper {
  ImagePickerHelper(this._imagePickerService);
  final ImagePickerService _imagePickerService;

  /// Показывает диалог выбора источника с использованием Apple стиля
  /// (для более современного и элегантного UI в соответствии с Apple HIG)
  ///
  /// Параметры:
  /// - [context] - контекст для отображения диалога
  /// - [maxWidth] - максимальная ширина изображения
  /// - [maxHeight] - максимальная высота изображения
  /// - [imageQuality] - качество изображения (0-100)
  /// - [allowMultiple] - разрешить выбор нескольких изображений из галереи
  /// - [limit] - максимальное количество изображений (для iOS 14+)
  ///
  /// Возвращает [XFile?] для одного изображения или [List<XFile>] для нескольких
  ///
  /// **Логика работы:**
  /// 1. Сразу показываем bottom sheet с выбором источника (камера/галерея)
  /// 2. При выборе источника проверяем разрешения
  /// 3. Если разрешения запрещены - показываем диалог для перехода в настройки
  Future<dynamic> showAppleStyleImageSourceDialog({
    required BuildContext context,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool allowMultiple = false,
    int? limit,
  }) async {
    // [showBottomSheetFirst] Сразу показываем bottom sheet с выбором источника
    // Проверка разрешений будет происходить при выборе конкретного источника
    // Показываем диалог и ждём выбора источника (камера/галерея/отмена)
    final String? sourceChoice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок с закругленным верхом
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Text(
                    'Select source',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: RishColors.textSecondary,
                        ),
                  ),
                ),

                // Кнопка "Камера"
                _buildAppleStyleButton(
                  context: dialogContext,
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => Navigator.pop(dialogContext, 'camera'),
                  isFirst: true,
                ),

                // Разделитель
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),

                // Кнопка "Галерея"
                _buildAppleStyleButton(
                  context: dialogContext,
                  icon: Icons.photo_library_rounded,
                  label: allowMultiple ? 'Gallery (multiple)' : 'Gallery',
                  onTap: () => Navigator.pop(dialogContext, 'gallery'),
                  isLast: true,
                ),

                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(dialogContext),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: RishColors.error,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    // Если пользователь отменил выбор, возвращаем null
    if (sourceChoice == null) {
      print('[ImagePickerHelper] Пользователь отменил выбор источника');
      return null;
    }

    // Выполняем действие в зависимости от выбора
    print('[ImagePickerHelper] Выбран источник: $sourceChoice');

    if (sourceChoice == 'camera') {
      // [checkCameraPermissionBeforeOpen] Проверяем статус разрешения на камеру перед открытием
      // Если разрешение запрещено - показываем диалог для перехода в настройки
      final cameraStatus = await Permission.camera.status;
      
      if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
        // Разрешение запрещено - показываем диалог
        if (context.mounted) {
          await RishiDialog.showPermissionDeniedDialog(
            context,
            permissionType: 'camera',
          );
        }
        return null;
      }

      // На Android запрашиваем разрешение, если оно еще не предоставлено
      // На iOS разрешение запрашивается автоматически через image_picker
      if (Platform.isAndroid && !cameraStatus.isGranted && !cameraStatus.isLimited) {
        try {
          await _checkAndRequestCameraPermission(context: context);
        } catch (e) {
          // Если запрос разрешения был отклонен, показываем диалог
          // Метод _checkAndRequestCameraPermission уже показал диалог для permanently denied,
          // но для обычного denied мы показываем диалог здесь
          final updatedStatus = await Permission.camera.status;
          if (updatedStatus.isDenied || updatedStatus.isPermanentlyDenied) {
            if (context.mounted) {
              await RishiDialog.showPermissionDeniedDialog(
                context,
                permissionType: 'camera',
              );
            }
          }
          return null;
        }
      }

      // Открываем камеру
      // На iOS разрешения запрашиваются автоматически при первом обращении
      try {
        final XFile? photo = await _imagePickerService.takePhoto(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );
        print('[ImagePickerHelper] Результат камеры: ${photo?.path ?? "null"}');
        return photo;
      } catch (e) {
        // Если пользователь отменил выбор или ошибка не связана с разрешениями,
        // возвращаем null без исключения
        print('[ImagePickerHelper] Ошибка при съемке фото: $e');
        
        // [checkPermissionAfterError] Проверяем статус разрешения после ошибки
        // Если разрешение запрещено, показываем диалог
        final cameraStatus = await Permission.camera.status;
        if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
          // Показываем диалог с предложением открыть настройки
          if (context.mounted) {
            await RishiDialog.showPermissionDeniedDialog(
              context,
              permissionType: 'camera',
            );
          }
          return null;
        }
        
        // Проверяем, является ли это ошибкой разрешения по тексту ошибки
        if (e.toString().toLowerCase().contains('permission') ||
            e.toString().toLowerCase().contains('denied')) {
          // Показываем диалог с предложением открыть настройки
          if (context.mounted) {
            await RishiDialog.showPermissionDeniedDialog(
              context,
              permissionType: 'camera',
            );
          }
        }
        // Иначе это просто отмена или другая некритичная ошибка
        return null;
      }
    } else if (sourceChoice == 'gallery') {
      // [checkGalleryPermissionBeforeOpen] На Android 10+ (API 29+) с scoped storage
      // разрешение может не требоваться для системного picker, и статус Permission.photos
      // может быть неправильным даже когда доступ предоставлен.
      // Поэтому на Android не проверяем разрешение заранее, а просто пытаемся открыть галерею.
      // На iOS проверяем разрешение перед открытием.
      
      if (Platform.isIOS) {
        // На iOS проверяем разрешение перед открытием
        final galleryStatus = await Permission.photos.status;
        
        if (galleryStatus.isDenied || galleryStatus.isPermanentlyDenied) {
          // Разрешение запрещено - показываем диалог
          if (context.mounted) {
            await RishiDialog.showPermissionDeniedDialog(
              context,
              permissionType: 'gallery',
            );
          }
          return null;
        }
      } else {
        // На Android проверяем только permanently denied
        // На Android 10+ с scoped storage разрешение может быть denied, но доступ все равно работать
        final galleryStatus = await Permission.photos.status;
        
        if (galleryStatus.isPermanentlyDenied) {
          // Разрешение постоянно запрещено - показываем диалог
          if (context.mounted) {
            await RishiDialog.showPermissionDeniedDialog(
              context,
              permissionType: 'gallery',
            );
          }
          return null;
        }

        // На Android запрашиваем разрешение, если оно еще не предоставлено
        // Но не блокируем доступ, если оно denied (может работать через scoped storage)
        if (!galleryStatus.isGranted && !galleryStatus.isLimited) {
          try {
            await _checkAndRequestGalleryPermission(context: context);
          } catch (e) {
            // Если запрос разрешения был отклонен, не блокируем доступ
            // Попробуем открыть галерею - может работать через scoped storage
            print('[ImagePickerHelper] Запрос разрешения на галерею отклонен, но продолжаем попытку открыть галерею');
          }
        }
      }

      // Открываем галерею
      // На iOS разрешения запрашиваются автоматически при первом обращении
      try {
        if (allowMultiple && (limit == null || limit > 1)) {
          // Используем multiple picker только если limit > 1 или не указан
          final List<XFile> images =
              await _imagePickerService.pickMultipleImages(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            imageQuality: imageQuality,
            limit: limit,
          );
          print(
            '[ImagePickerHelper] Результат галереи (multiple): ${images.length} фото',
          );
          // Если список пустой (пользователь отменил выбор), возвращаем null
          return images.isEmpty ? null : images;
        } else {
          // Используем одиночный picker если limit == 1 или allowMultiple == false
          final XFile? image = await _imagePickerService.pickImageFromGallery(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            imageQuality: imageQuality,
          );
          print(
            '[ImagePickerHelper] Результат галереи (single): ${image?.path ?? "null"}',
          );
          // Возвращаем как список для совместимости с allowMultiple
          return image != null ? [image] : null;
        }
      } catch (e) {
        // Если пользователь отменил выбор или ошибка не связана с разрешениями,
        // возвращаем null без исключения
        print('[ImagePickerHelper] Ошибка при выборе из галереи: $e');
        
        // [checkPermissionAfterError] Проверяем статус разрешения после ошибки
        // Если разрешение запрещено, показываем диалог
        final galleryStatus = await Permission.photos.status;
        if (galleryStatus.isDenied || galleryStatus.isPermanentlyDenied) {
          // Показываем диалог с предложением открыть настройки
          if (context.mounted) {
            await RishiDialog.showPermissionDeniedDialog(
              context,
              permissionType: 'gallery',
            );
          }
          return null;
        }
        
        // Проверяем, является ли это ошибкой разрешения по тексту ошибки
        if (e.toString().toLowerCase().contains('permission') ||
            e.toString().toLowerCase().contains('denied')) {
          // Показываем диалог с предложением открыть настройки
          if (context.mounted) {
            await RishiDialog.showPermissionDeniedDialog(
              context,
              permissionType: 'gallery',
            );
          }
        }
        // Иначе это просто отмена или другая некритичная ошибка
        return null;
      }
    }

    return null;
  }

  /// [_checkAndRequestCameraPermission] Проверяет и запрашивает разрешение на камеру
  ///
  /// Используется только на Android. На iOS разрешения запрашиваются автоматически
  /// через image_picker при первом обращении к камере.
  ///
  /// Проверяет статус разрешения на камеру и запрашивает его, если оно не предоставлено.
  /// Если разрешение постоянно запрещено, показывает диалог с предложением открыть настройки.
  ///
  /// **Параметры:**
  /// - context: Контекст для показа диалога (требуется если разрешение постоянно запрещено)
  ///
  /// **Выбрасывает:**
  /// Exception если разрешение не предоставлено или запрос отклонен
  ///
  Future<void> _checkAndRequestCameraPermission({
    required BuildContext context,
  }) async {
    print(
      '[ImagePickerHelper._checkAndRequestCameraPermission] Проверка разрешения на камеру',
    );

    final PermissionStatus cameraStatus = await Permission.camera.status;
    print(
      '[ImagePickerHelper._checkAndRequestCameraPermission] Статус камеры: $cameraStatus',
    );

    // Если разрешение уже предоставлено, ничего не делаем
    if (cameraStatus.isGranted) {
      print(
        '[ImagePickerHelper._checkAndRequestCameraPermission] Разрешение на камеру уже предоставлено',
      );
      return;
    }

    // Если разрешение ограничено (только для iOS), пытаемся запросить
    if (cameraStatus.isLimited) {
      print(
        '[ImagePickerHelper._checkAndRequestCameraPermission] Разрешение на камеру ограничено',
      );
      return;
    }

    // Если разрешение не предоставлено, запрашиваем его
    print(
      '[ImagePickerHelper._checkAndRequestCameraPermission] Запрос разрешения на камеру',
    );
    final PermissionStatus requestedStatus = await Permission.camera.request();

    print(
      '[ImagePickerHelper._checkAndRequestCameraPermission] Результат запроса: $requestedStatus',
    );

    if (!requestedStatus.isGranted && !requestedStatus.isLimited) {
      if (requestedStatus.isPermanentlyDenied) {
        // Показываем диалог с предложением открыть настройки
        if (context.mounted) {
          await RishiDialog.showPermissionDeniedDialog(
            context,
            permissionType: 'camera',
          );
        }
        throw Exception(
          'Camera permission is permanently denied. Please enable it in device settings.',
        );
      } else {
        throw Exception('Camera permission denied');
      }
    }
  }

  /// [_checkAndRequestGalleryPermission] Проверяет и запрашивает разрешение на галерею
  ///
  /// Используется только на Android. На iOS разрешения запрашиваются автоматически
  /// через image_picker при первом обращении к галерее.
  ///
  /// Проверяет статус разрешения на галерею и запрашивает его, если оно не предоставлено.
  /// Если разрешение постоянно запрещено, показывает диалог с предложением открыть настройки.
  ///
  /// **Параметры:**
  /// - context: Контекст для показа диалога (требуется если разрешение постоянно запрещено)
  ///
  /// **Выбрасывает:**
  /// Exception если разрешение не предоставлено или запрос отклонен
  ///
  Future<void> _checkAndRequestGalleryPermission({
    required BuildContext context,
  }) async {
    print(
      '[ImagePickerHelper._checkAndRequestGalleryPermission] Проверка разрешения на галерею',
    );

    // Permission.photos работает на Android 13+ и iOS
    // На старых версиях Android автоматически обрабатывается через Permission.storage
    final PermissionStatus galleryStatus = await Permission.photos.status;
    print(
      '[ImagePickerHelper._checkAndRequestGalleryPermission] Статус галереи: $galleryStatus',
    );

    // Если разрешение уже предоставлено, ничего не делаем
    if (galleryStatus.isGranted) {
      print(
        '[ImagePickerHelper._checkAndRequestGalleryPermission] Разрешение на галерею уже предоставлено',
      );
      return;
    }

    // Если разрешение ограничено (только для iOS), пытаемся запросить
    if (galleryStatus.isLimited) {
      print(
        '[ImagePickerHelper._checkAndRequestGalleryPermission] Разрешение на галерею ограничено',
      );
      return;
    }

    // Если разрешение не предоставлено, запрашиваем его
    print(
      '[ImagePickerHelper._checkAndRequestGalleryPermission] Запрос разрешения на галерею',
    );
    final PermissionStatus requestedStatus = await Permission.photos.request();

    print(
      '[ImagePickerHelper._checkAndRequestGalleryPermission] Результат запроса: $requestedStatus',
    );

    if (!requestedStatus.isGranted && !requestedStatus.isLimited) {
      if (requestedStatus.isPermanentlyDenied) {
        // Показываем диалог с предложением открыть настройки
        if (context.mounted) {
          await RishiDialog.showPermissionDeniedDialog(
            context,
            permissionType: 'gallery',
          );
        }
        throw Exception(
          'Gallery permission is permanently denied. Please enable it in device settings.',
        );
      } else {
        throw Exception('Gallery permission denied');
      }
    }
  }

  /// Вспомогательный метод для создания кнопки в Apple стиле
  Widget _buildAppleStyleButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(14) : Radius.zero,
          bottom: isLast ? const Radius.circular(14) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(
                icon,
                color: RishColors.primary,
                size: 28,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: RishColors.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
