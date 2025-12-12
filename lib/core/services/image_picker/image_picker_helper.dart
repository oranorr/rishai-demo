import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rishai/core/services/image_picker/image_picker_service.dart';
import 'package:rishai/core/services/permissions/permission_service.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/dialog.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ImagePickerHelper
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Вспомогательный класс для отображения диалогов выбора источника изображения.
///
/// **Функциональность:**
/// - Показ bottom sheet с выбором источника (камера/галерея)
/// - Запрос разрешений через PermissionService
/// - Показ snackbar при отказе в разрешении
/// - Показ popup с настройками при повторном нажатии без разрешения
///
/// **Логика работы:**
/// 1. Показываем bottom sheet с выбором источника
/// 2. При выборе источника проверяем статус разрешения
/// 3. Если denied/permanentlyDenied - показываем popup с настройками (повторное нажатие)
/// 4. Иначе запрашиваем разрешение через PermissionService
/// 5. Если granted - открываем источник
/// 6. Если denied - показываем snackbar
/// 7. Если permanentlyDenied - показываем popup с настройками
class ImagePickerHelper {
  ImagePickerHelper(
    this._imagePickerService, {
    PermissionService? permissionService,
  }) : _permissionService = permissionService ?? PermissionService();

  final ImagePickerService _imagePickerService;
  final PermissionService _permissionService;

  /// [showAppleStyleImageSourceDialog] Показывает диалог выбора источника с использованием Apple стиля
  ///
  /// Показывает bottom sheet с выбором источника (камера/галерея) и обрабатывает
  /// запрос разрешений через PermissionService.
  ///
  /// **Параметры:**
  /// - [context] - контекст для отображения диалога
  /// - [maxWidth] - максимальная ширина изображения
  /// - [maxHeight] - максимальная высота изображения
  /// - [imageQuality] - качество изображения (0-100)
  /// - [allowMultiple] - разрешить выбор нескольких изображений из галереи
  /// - [limit] - максимальное количество изображений (для iOS 14+)
  ///
  /// **Возвращает:**
  /// - [XFile?] для одного изображения или [List<XFile>] для нескольких
  /// - null если выбор отменен или произошла ошибка
  ///
  /// **Логика работы:**
  /// 1. Показываем bottom sheet с выбором источника (камера/галерея)
  /// 2. При выборе источника проверяем статус разрешения
  /// 3. Если denied/permanentlyDenied - показываем popup с настройками (повторное нажатие)
  /// 4. Иначе запрашиваем разрешение через PermissionService
  /// 5. Если granted - открываем источник
  /// 6. Если denied - показываем snackbar
  /// 7. Если permanentlyDenied - показываем popup с настройками
  Future<dynamic> showAppleStyleImageSourceDialog({
    required BuildContext context,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool allowMultiple = false,
    int? limit,
  }) async {
    // [showBottomSheetFirst] Показываем bottom sheet с выбором источника
    // Проверка разрешений будет происходить при выборе конкретного источника
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
      print('[ImagePickerHelper.showAppleStyleImageSourceDialog] Пользователь отменил выбор источника');
      return null;
    }

    // Выполняем действие в зависимости от выбора
    print('[ImagePickerHelper.showAppleStyleImageSourceDialog] Выбран источник: $sourceChoice');

    if (sourceChoice == 'camera') {
      return await _handleCameraSource(
        context: context,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
    } else if (sourceChoice == 'gallery') {
      return await _handleGallerySource(
        context: context,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        allowMultiple: allowMultiple,
        limit: limit,
      );
    }

        return null;
  }

  /// [_handleCameraSource] Обрабатывает выбор камеры как источника
  ///
  /// Проверяет статус разрешения и запрашивает его при необходимости.
  /// Показывает snackbar при отказе и popup с настройками при повторном нажатии.
  Future<XFile?> _handleCameraSource({
    required BuildContext context,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    print('[ImagePickerHelper._handleCameraSource] Обработка выбора камеры');

    // [checkStatusBeforeRequest] Проверяем статус разрешения перед запросом
    // Проверяем только permanentlyDenied - это означает, что разрешение было запрещено в настройках
    // Если denied - это может быть первый раз (разрешение еще не запрашивалось), поэтому запрашиваем
    final PermissionStatus currentStatus = await _permissionService.getCameraStatus();
    
    if (currentStatus.isPermanentlyDenied) {
      print('[ImagePickerHelper._handleCameraSource] Разрешение permanentlyDenied - показываем popup с настройками');
      if (context.mounted) {
        await RishiDialog.showPermissionSettingsDialog(
          context,
          permissionType: 'camera',
        );
      }
      return null;
    }

    // [requestPermission] Запрашиваем разрешение через PermissionService
    final PermissionResult result = await _permissionService.requestCameraPermission();

    // [handlePermissionResult] Обрабатываем результат запроса разрешения
    if (result == PermissionResult.granted) {
      // Разрешение предоставлено - открываем камеру
      print('[ImagePickerHelper._handleCameraSource] ✅ Разрешение предоставлено, открываем камеру');
      try {
        final XFile? photo = await _imagePickerService.takePhoto(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );
        print('[ImagePickerHelper._handleCameraSource] Результат камеры: ${photo?.path ?? "null"}');
        return photo;
      } catch (e) {
        print('[ImagePickerHelper._handleCameraSource] Ошибка при съемке фото: $e');
        // Если пользователь отменил выбор или ошибка не связана с разрешениями,
        // возвращаем null без исключения
        return null;
      }
    } else if (result == PermissionResult.denied) {
      // Пользователь отказал в разрешении при запросе
      // Не показываем snackbar сразу - пользователь мог просто закрыть диалог разрешения
      // При следующем нажатии статус будет denied, и мы покажем popup с настройками
      print('[ImagePickerHelper._handleCameraSource] ⚠️ Пользователь отказал в разрешении - не показываем snackbar (может быть просто закрытие диалога)');
      return null;
    } else if (result == PermissionResult.permanentlyDenied) {
      // Разрешение постоянно запрещено - показываем popup с настройками
      print('[ImagePickerHelper._handleCameraSource] ❌ Разрешение постоянно запрещено - показываем popup с настройками');
      if (context.mounted) {
        await RishiDialog.showPermissionSettingsDialog(
          context,
          permissionType: 'camera',
        );
      }
      return null;
    }

    return null;
  }

  /// [_handleGallerySource] Обрабатывает выбор галереи как источника
  ///
  /// Проверяет статус разрешения и запрашивает его при необходимости.
  /// Показывает snackbar при отказе и popup с настройками при повторном нажатии.
  ///
  /// **Особенности для Android:**
  /// - На Android 10+ галерея может работать через scoped storage без явного разрешения
  /// - Поэтому на Android не блокируем доступ при denied, а пробуем открыть галерею
  Future<dynamic> _handleGallerySource({
    required BuildContext context,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool allowMultiple = false,
    int? limit,
  }) async {
    print('[ImagePickerHelper._handleGallerySource] Обработка выбора галереи');

    // [checkStatusBeforeRequest] Проверяем статус разрешения перед запросом
    // Проверяем только permanentlyDenied - это означает, что разрешение было запрещено в настройках
    // Если denied - это может быть первый раз (разрешение еще не запрашивалось), поэтому запрашиваем
    // На Android denied может означать, что разрешение не нужно (scoped storage)
    final PermissionStatus currentStatus = await _permissionService.getGalleryStatus();
    
    if (currentStatus.isPermanentlyDenied) {
      print('[ImagePickerHelper._handleGallerySource] Разрешение permanentlyDenied - показываем popup с настройками');
      if (context.mounted) {
        await RishiDialog.showPermissionSettingsDialog(
          context,
          permissionType: 'gallery',
        );
      }
      return null;
    }

    // [requestPermission] Запрашиваем разрешение через PermissionService
    final PermissionResult result = await _permissionService.requestGalleryPermission();

    // [handlePermissionResult] Обрабатываем результат запроса разрешения
    if (result == PermissionResult.granted) {
      // Разрешение предоставлено - открываем галерею
      return await _openGallery(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        allowMultiple: allowMultiple,
        limit: limit,
      );
    } else if (result == PermissionResult.denied) {
      // Пользователь отказал в разрешении
      if (Platform.isAndroid) {
        // На Android пробуем открыть галерею, так как может работать через scoped storage
        print('[ImagePickerHelper._handleGallerySource] Android: Разрешение denied, но пробуем открыть галерею через scoped storage');
        final galleryResult = await _openGallery(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
          allowMultiple: allowMultiple,
          limit: limit,
        );
        
        // Возвращаем результат (может быть null, если пользователь закрыл галерею)
        // Не показываем snackbar, так как null означает просто отмену выбора, а не ошибку доступа
        return galleryResult;
      } else {
        // На iOS если разрешение denied, это означает что пользователь явно отказал
        // Но не показываем snackbar сразу - пользователь мог просто закрыть диалог разрешения
        // Snackbar показываем только при повторном нажатии (когда статус уже denied)
        print('[ImagePickerHelper._handleGallerySource] iOS: Разрешение denied, но не показываем snackbar (может быть просто закрытие диалога)');
        return null;
      }
    } else if (result == PermissionResult.permanentlyDenied) {
      // Разрешение постоянно запрещено - показываем popup с настройками
      print('[ImagePickerHelper._handleGallerySource] ❌ Разрешение постоянно запрещено - показываем popup с настройками');
      if (context.mounted) {
        await RishiDialog.showPermissionSettingsDialog(
          context,
          permissionType: 'gallery',
        );
      }
      return null;
    }

    return null;
  }

  /// [_openGallery] Открывает галерею для выбора изображений
  ///
  /// Вспомогательный метод для открытия галереи с обработкой ошибок.
  Future<dynamic> _openGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool allowMultiple = false,
    int? limit,
  }) async {
    try {
      // [decidePickerType] Определяем тип picker'а на основе allowMultiple и limit
      // pickMultiImage не принимает limit: 1 (минимум 2), поэтому для limit == 1
      // используем одиночный picker даже если allowMultiple == true
      final bool shouldUseMultiplePicker = allowMultiple && (limit == null || limit > 1);
      
      if (shouldUseMultiplePicker) {
        // [useMultiplePicker] Используем множественный выбор для limit > 1 или без лимита
        final List<XFile> images = await _imagePickerService.pickMultipleImages(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
          limit: limit,
        );
        print('[ImagePickerHelper._openGallery] Результат галереи (multiple): ${images.length} фото (limit: $limit)');
        
        // [validateLimit] Обрезаем список до лимита, если он указан
        final List<XFile> finalImages;
        if (limit != null && images.length > limit) {
          print('[ImagePickerHelper._openGallery] ⚠️ Выбрано ${images.length} фото, но лимит: $limit. Обрезаем до лимита.');
          finalImages = images.take(limit).toList();
        } else {
          finalImages = images;
        }
        
        // Если список пустой (пользователь отменил выбор), возвращаем null
        return finalImages.isEmpty ? null : finalImages;
      } else {
        // [useSinglePicker] Используем одиночный picker если:
        // - allowMultiple == false, или
        // - limit == 1 (pickMultiImage не поддерживает limit: 1)
        final XFile? image = await _imagePickerService.pickImageFromGallery(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );
        print('[ImagePickerHelper._openGallery] Результат галереи (single): ${image?.path ?? "null"} (limit: $limit, allowMultiple: $allowMultiple)');
        // Возвращаем как список для совместимости с allowMultiple
        return image != null ? [image] : null;
      }
    } catch (e) {
      print('[ImagePickerHelper._openGallery] Ошибка при выборе из галереи: $e');
      // Если пользователь отменил выбор или ошибка не связана с разрешениями,
      // возвращаем null без исключения
      return null;
    }
  }

  /// [_buildAppleStyleButton] Вспомогательный метод для создания кнопки в Apple стиле
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
