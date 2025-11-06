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
  Future<dynamic> showAppleStyleImageSourceDialog({
    required BuildContext context,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool allowMultiple = false,
    int? limit,
  }) async {
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
      // На Android проверяем и запрашиваем разрешение на камеру
      // На iOS разрешение запрашивается автоматически через image_picker
      if (Platform.isAndroid) {
        await _checkAndRequestCameraPermission(context: context);
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
        // Проверяем, является ли это ошибкой разрешения
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
      // На Android проверяем и запрашиваем разрешение на галерею
      // На iOS разрешение запрашивается автоматически через image_picker
      if (Platform.isAndroid) {
        await _checkAndRequestGalleryPermission(context: context);
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
        // Проверяем, является ли это ошибкой разрешения
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
