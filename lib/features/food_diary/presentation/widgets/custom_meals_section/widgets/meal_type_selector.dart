import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/features/chat/domain/entities/serving_entity.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MealTypeSelector Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Селектор типа приема пищи (завтрак, обед, ужин, перекус).
///
/// **UI/UX:**
/// - Список радиокнопок для каждого типа
/// - Разделители между элементами
/// - Подсветка выбранного элемента
///
class MealTypeSelector extends StatelessWidget {
  const MealTypeSelector({
    this.selectedType,
    this.onTypeChanged,
    super.key,
  });

  /// Выбранный тип приема пищи
  final ServingType? selectedType;

  /// Callback при изменении типа
  final ValueChanged<ServingType>? onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ServingType.values.map((type) {
        final isSelected = selectedType == type;
        return Column(
          children: [
            MealTypeRadioItem(
              type: type,
              isSelected: isSelected,
              onTap: () => onTypeChanged?.call(type),
            ),
            const Divider(color: RishColors.stroke, height: 1),
          ],
        );
      }).toList(),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// MealTypeRadioItem Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Элемент радиокнопки для выбора типа приема пищи.
///
class MealTypeRadioItem extends StatelessWidget {
  const MealTypeRadioItem({
    required this.type,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final ServingType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Название типа приема пищи
            Text(type.name, style: context.styles.regularMedium),
            const Spacer(),

            // Радиокнопка
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? RishColors.primary
                      : RishColors.textSecondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: RishColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

