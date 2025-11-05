import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/photo_placeholder.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/photo_preview_item.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PhotosGallery Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Галерея для отображения выбранных фотографий с плейсхолдерами.
///
/// **Функциональность:**
/// - Всегда отображает 3 слота для фотографий
/// - Занятые слоты показывают превью фотографий с кнопкой удаления
/// - Пустые слоты показывают плейсхолдеры с пунктирной границей и иконкой камеры
/// - Клик по плейсхолдеру открывает диалог выбора фото
///
/// **UI/UX:**
/// - Минималистичный дизайн в стиле Apple HIG
/// - Пунктирная граница для плейсхолдеров
/// - Иконка камеры с плюсом в центре плейсхолдера
/// - Плавные анимации взаимодействия
///
class PhotosGallery extends StatelessWidget {
  const PhotosGallery({
    required this.photos,
    required this.onRemove,
    required this.onAddPhoto,
    super.key,
  });

  /// Список выбранных фотографий
  final List<XFile> photos;

  /// Callback для удаления фотографии по индексу
  final ValueChanged<int> onRemove;

  /// Callback для добавления новой фотографии
  final VoidCallback onAddPhoto;

  /// Максимальное количество фотографий (слотов)
  static const int maxSlots = 3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 95.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: maxSlots,
        itemBuilder: (context, index) {
          // Если индекс меньше количества фото — показываем фото
          if (index < photos.length) {
            print(
              '[PhotosGallery] Отрисовка фото $index: ${photos[index].path}',
            );
            return PhotoPreviewItem(
              photo: photos[index],
              onRemove: () => onRemove(index),
            );
          }

          // Иначе показываем плейсхолдер
          print('[PhotosGallery] Отрисовка плейсхолдера $index');
          return PhotoPlaceholder(onTap: onAddPhoto);
        },
      ),
    );
  }
}

