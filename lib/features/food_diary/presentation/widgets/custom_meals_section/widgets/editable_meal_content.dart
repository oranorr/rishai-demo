import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';
import 'package:rishai/features/food_diary/domain/entities/custom_meal_entry.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/camera_button.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/meal_type_selector.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/photos_gallery.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EditableMealContent Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Виджет для редактирования кастомного блюда.
///
/// **Функциональность:**
/// - Селектор типа приема пищи
/// - Галерея фотографий с плейсхолдерами
/// - Поле ввода описания с кнопкой камеры
/// - Кнопка отправки запроса на анализ
///
/// **UI/UX:**
/// - Минималистичный дизайн в стиле Apple HIG
/// - Удобное взаимодействие с фотографиями
/// - Валидация перед отправкой
///
class EditableMealContent extends StatelessWidget {
  const EditableMealContent({
    required this.meal,
    required this.descriptionController,
    required this.isLoading,
    required this.onMealTypeChanged,
    required this.onPhotoRemove,
    required this.onCameraTap,
    required this.onSendRequest,
    super.key,
  });

  /// Данные кастомного блюда
  final CustomMealEntry meal;

  /// Контроллер для текстового поля описания
  final TextEditingController descriptionController;

  /// Флаг загрузки при отправке запроса
  final bool isLoading;

  /// Callback при изменении типа приема пищи
  final ValueChanged<ServingType> onMealTypeChanged;

  /// Callback для удаления фотографии по индексу
  final ValueChanged<int> onPhotoRemove;

  /// Callback для нажатия на кнопку камеры
  final VoidCallback onCameraTap;

  /// Callback для отправки запроса на анализ
  final VoidCallback onSendRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Селектор типа приема пищи                                        │
        // └─────────────────────────────────────────────────────────────────┘
        MealTypeSelector(
          selectedType: meal.mealType,
          onTypeChanged: onMealTypeChanged,
        ),
        SizedBox(height: 12.h),

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Галерея фотографий (отображается всегда с плейсхолдерами)        │
        // └─────────────────────────────────────────────────────────────────┘
        PhotosGallery(
          photos: meal.photos,
          onRemove: onPhotoRemove,
          onAddPhoto: onCameraTap,
        ),
        SizedBox(height: 12.h),

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Поле ввода описания с кнопкой камеры                             │
        // └─────────────────────────────────────────────────────────────────┘
        DecoratedBox(
          decoration: BoxDecoration(
            color: RishColors.formBackgroun,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Текстовое поле для описания блюда
              Expanded(
                child: TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Add meal description',
                    hintStyle: context.styles.regularMedium.copyWith(
                      color: RishColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  style: context.styles.regularMedium,
                ),
              ),
              SizedBox(width: 8.w),

              // Круглая кнопка камеры
              AnalyzeButton(
                isEnabled: meal.hasPhotos || meal.hasDescription,
                onTap: onSendRequest,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }
}
