import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/features/food_diary/presentation/widgets/custom_meals_section/widgets/dashed_border_painter.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PhotoPlaceholder Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Плейсхолдер для пустого слота фотографии.
///
/// **UI/UX:**
/// - Квадратный контейнер 90x90
/// - Пунктирная граница (dashed border)
/// - Иконка камеры с плюсом в центре
/// - Полупрозрачный фон
/// - Соответствует Apple HIG для плейсхолдеров
///
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({required this.onTap, super.key});

  /// Callback при нажатии на плейсхолдер
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90.w,
        height: 90.w,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: RishColors.formBackgroun.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: RishColors.textSecondary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: RishColors.textSecondary.withOpacity(0.4),
            strokeWidth: 2,
            dashWidth: 6,
            dashSpace: 4,
            borderRadius: 12,
          ),
          child: Center(
            child: Icon(
              Icons.add_a_photo_outlined,
              size: 32.w,
              color: RishColors.textSecondary.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

