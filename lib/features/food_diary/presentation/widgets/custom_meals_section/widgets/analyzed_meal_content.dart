import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/features/food_diary/domain/diary_meal.dart';
import 'package:rishai/features/food_diary/domain/entities/custom_meal_entry.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AnalyzedMealContent Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Виджет для отображения проанализированного блюда в read-only режиме.

class AnalyzedMealContent extends StatelessWidget {
  const AnalyzedMealContent({
    required this.meal,
    required this.analyzedMeal,
    required this.isRegenerating,
    required this.onDelete,
    required this.onRegenerate,
    required this.onToggleSelection,
    super.key,
  });

  /// Данные кастомного блюда
  final CustomMealEntry meal;

  /// Результат анализа блюда
  final DiaryMeal analyzedMeal;

  /// Флаг загрузки при регенерации
  final bool isRegenerating;

  /// Callback для удаления блюда
  final VoidCallback onDelete;

  /// Callback для регенерации анализа
  final VoidCallback onRegenerate;

  /// Callback для переключения выбора блюда
  final VoidCallback onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = meal.photos.isNotEmpty;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ┌─────────────────────────────────────────────────────────────────┐
              // │ Фотография блюда (если есть)                                     │
              // └─────────────────────────────────────────────────────────────────┘
              if (hasPhoto) ...[
                SizedBox(
                  width: 94.w,
                  height: 94.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(meal.photos.first.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
              ],

              // ┌─────────────────────────────────────────────────────────────────┐
              // │ Информация о блюде                                               │
              // └─────────────────────────────────────────────────────────────────┘
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ┌───────────────────────────────────────────────────────────────┐
                    // │ Название блюда                                                 │
                    // └───────────────────────────────────────────────────────────────┘
                    Text(
                      analyzedMeal.title,
                      style: context.styles.boldMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // ┌───────────────────────────────────────────────────────────────┐
                    // │ Информация о питательности                                     │
                    // └───────────────────────────────────────────────────────────────┘
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 8.h,
                      children: [
                        // Макронутриенты
                        Text(
                          'Protein ${analyzedMeal.macros.protein}',
                          style: context.styles.regularSmall,
                        ),
                        Text(
                          'Fats ${analyzedMeal.macros.fat}',
                          style: context.styles.regularSmall,
                        ),
                        Text(
                          'Carbs ${analyzedMeal.macros.carbs}',
                          style: context.styles.regularSmall,
                        ),
                        // Калорийность
                        Text(
                          '${analyzedMeal.macros.kcal} Kcals',
                          style: context.styles.regularMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // ┌─────────────────────────────────────────────────────────────────┐
          // │ Панель действий с кнопками                                       │
          // └─────────────────────────────────────────────────────────────────┘
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Кнопка удаления
              GestureDetector(
                onTap: isRegenerating ? null : onDelete,
                child: Opacity(
                  opacity: isRegenerating ? 0.5 : 1.0,
                  child: SvgPicture.asset('assets/icons/trash.svg'),
                ),
              ),

              // Кнопка регенерации / Индикатор загрузки
              GestureDetector(
                onTap: isRegenerating ? null : onRegenerate,
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: isRegenerating
                      ? CircularProgressIndicator(
                          strokeWidth: 2.w,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            RishColors.primary,
                          ),
                        )
                      : const Icon(Icons.refresh),
                ),
              ),

              // Кнопка подтверждения / выбора для добавления в дневник
              GestureDetector(
                onTap: isRegenerating ? null : onToggleSelection,
                child: Opacity(
                  opacity: isRegenerating ? 0.5 : 1.0,
                  child: SvgPicture.asset(
                    'assets/icons/checkmark-circle.svg',
                    colorFilter: ColorFilter.mode(
                      meal.isSelected
                          ? RishColors.primary
                          : RishColors.textSecondary.withOpacity(0.3),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
