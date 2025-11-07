import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/extensions/string_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/core/widgets/dialog.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/services/adapty_service/adapty_repository_impl.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/features/food_diary/domain/entities/custom_meal_entry.dart'
    show CustomMealEntry;
import 'package:rishai/features/food_diary/presentation/bloc/food_diary_cubit.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/handlers/image_picker_handler.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/handlers/meal_analysis_handler.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/analyzed_meal_content.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/editable_meal_content.dart';
import 'package:rishai/features/food_diary/presentation/widgets/diary_dropdown.dart';

part '../mixins/custom_meal_item_mixin.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CustomMealItem Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Виджет для одного кастомного блюда.
///
/// **Функциональность:**
/// - Dropdown с содержимым блюда
/// - Галерея фотографий с плейсхолдерами
/// - Селектор типа приема пищи
/// - Текстовое поле описания
/// - Кнопка камеры
/// - Кнопка "Send"
/// - Кнопка удаления (X) если больше 1 блюда
///
class CustomMealItem extends StatefulWidget {
  const CustomMealItem({
    required this.meal,
    required this.mealIndex,
    required this.showDeleteButton,
    super.key,
  });

  /// Данные кастомного блюда
  final CustomMealEntry meal;

  /// Индекс блюда для отображения (1-based)
  final int mealIndex;

  /// Показывать ли кнопку удаления
  final bool showDeleteButton;

  @override
  State<CustomMealItem> createState() => _CustomMealItemState();
}

class _CustomMealItemState extends State<CustomMealItem>
    with CustomMealItemMixin {
  @override
  Widget build(BuildContext context) {
    // Определяем заголовок dropdown
    // Если блюдо проанализировано - показываем название блюда
    // Иначе - показываем тип приема пищи или placeholder
    final dropdownTitle =
        widget.meal.mealType?.name.capitalize() ?? 'Choose from the list';
    //  widget.meal.isAnalyzed
    //     ? widget.meal.analyzedMeal!.title
    //     : (widget.meal.mealType?.name ?? 'Choose from the list');

    // Dropdown должен быть открыт если есть фото или если блюдо проанализировано
    final initiallyExpanded = widget.meal.hasPhotos || widget.meal.isAnalyzed;

    return Column(
      children: [
        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Кнопка удаления сверху (если больше 1 блюда)                     │
        // └─────────────────────────────────────────────────────────────────┘
        if (widget.showDeleteButton && !widget.meal.isAnalyzed)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _handleDelete,
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Delete meal',
                      style: context.styles.regularSmall.copyWith(
                        color: RishColors.error,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.delete_outline,
                      size: 16.w,
                      color: RishColors.error,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Dropdown с содержимым блюда                                      │
        // └─────────────────────────────────────────────────────────────────┘
        DiaryDropDown(
          title: dropdownTitle,
          initiallyExpanded: initiallyExpanded,
          child: widget.meal.isAnalyzed
              ? AnalyzedMealContent(
                  meal: widget.meal,
                  analyzedMeal: widget.meal.analyzedMeal!,
                  isRegenerating: _isRegenerating,
                  onDelete: _handleDeleteAnalyzedMeal,
                  onRegenerate: _handleRegenerateAnalysis,
                  onToggleSelection: _handleToggleSelection,
                )
              : EditableMealContent(
                  meal: widget.meal,
                  descriptionController: _descriptionController,
                  isLoading: _isLoading,
                  onMealTypeChanged: (type) {
                    context.read<FoodDiaryCubit>().add(
                          CustomMealSetMealType(
                            mealId: widget.meal.id,
                            mealType: type,
                          ),
                        );
                  },
                  onPhotoRemove: _removePhoto,
                  onCameraTap: _handleCameraTap,
                  onSendRequest: _handleSendRequest,
                ),
        ),
      ],
    );
  }
}
