import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/features/chat/domain/entities/meal_plan_entity.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MealItem Widget
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Виджет для отображения элемента блюда с информацией о питательности.
/// Поддерживает выбор/снятие выбора с анимированными переходами.
/// 
/// **Отображаемая информация:**
/// - Название блюда
/// - Макронутриенты (белки, жиры, углеводы)
/// - Калорийность
/// - Тип приема пищи (завтрак, обед, ужин)
/// - Индикатор выбора (чекбокс)
/// 
/// **UI/UX особенности:**
/// - Плавная анимация выбора (200ms)
/// - Анимированный чекбокс с галочкой
/// - Tactile feedback при нажатии
/// - Следует Apple HIG для interactive elements
/// 
class MealItem extends StatefulWidget {
  const MealItem({
    super.key,
    required this.meal,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  /// Объект блюда с информацией о макронутриентах
  final Meal meal;

  /// Текущее состояние выбора
  final bool isSelected;

  /// Callback для изменения состояния выбора
  final ValueChanged<bool> onSelectionChanged;

  @override
  State<MealItem> createState() => _MealItemState();
}

class _MealItemState extends State<MealItem> {
  /// ═══════════════════════════════════════════════════════════════════════
  /// _toggleSelection
  /// ═══════════════════════════════════════════════════════════════════════
  /// 
  /// Переключает состояние выбора блюда и вызывает callback
  /// для обновления родительского состояния.
  /// 
  void _toggleSelection() {
    print('[MealItem._toggleSelection] Переключение выбора: ${widget.meal.title} -> ${!widget.isSelected}');
    widget.onSelectionChanged(!widget.isSelected);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleSelection,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: RishColors.formBackgroun,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ┌───────────────────────────────────────────────────────────────┐
            // │ Заголовок блюда                                               │
            // └───────────────────────────────────────────────────────────────┘
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.meal.title,
                    style: context.styles.boldMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ┌───────────────────────────────────────────────────────────────┐
            // │ Информация о питательности и чекбокс выбора                   │
            // └───────────────────────────────────────────────────────────────┘
            Row(
              children: [
                // ┌───────────────────────────────────────────────────────────┐
                // │ Макронутриенты                                            │
                // └───────────────────────────────────────────────────────────┘
                Text(
                  'Protein ${widget.meal.macros.protein}',
                  style: context.styles.regularSmall,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Fats ${widget.meal.macros.fat}',
                  style: context.styles.regularSmall,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Carbs ${widget.meal.macros.carbs}',
                  style: context.styles.regularSmall,
                ),
                const Spacer(),
                
                // ┌───────────────────────────────────────────────────────────┐
                // │ Калорийность                                              │
                // └───────────────────────────────────────────────────────────┘
                Text(
                  '${widget.meal.macros.kcal} Kcals',
                  style: context.styles.regularMedium,
                ),
                SizedBox(width: 8.w),
                
                // ┌───────────────────────────────────────────────────────────┐
                // │ Анимированный чекбокс с галочкой                          │
                // │ Плавный переход цвета и размера согласно Apple HIG        │
                // └───────────────────────────────────────────────────────────┘
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected
                        ? RishColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: widget.isSelected
                          ? RishColors.primary
                          : RishColors.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: widget.isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 16.w,
                        )
                      : null,
                ),
              ],
            ),
            
            // ┌───────────────────────────────────────────────────────────────┐
            // │ Тип приема пищи (Breakfast, Lunch, Dinner)                    │
            // └───────────────────────────────────────────────────────────────┘
            Text(
              widget.meal.type,
              style: context.styles.regularSmall.copyWith(
                color: RishColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

