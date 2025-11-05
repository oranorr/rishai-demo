import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rishai/core/services/image_picker/image_picker_service.dart';
import 'package:rishai/core/theme/theme_colors.dart';

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
      // Открываем камеру
      final XFile? photo = await _imagePickerService.takePhoto(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      print('[ImagePickerHelper] Результат камеры: ${photo?.path ?? "null"}');
      return photo;
    } else if (sourceChoice == 'gallery') {
      // Открываем галерею
      if (allowMultiple && (limit == null || limit > 1)) {
        // Используем multiple picker только если limit > 1 или не указан
        final List<XFile> images = await _imagePickerService.pickMultipleImages(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
          limit: limit,
        );
        print(
          '[ImagePickerHelper] Результат галереи (multiple): ${images.length} фото',
        );
        return images;
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
    }

    return null;
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
