import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/theme/theme_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CameraButton Widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Круглая кнопка камеры для добавления фотографий.
///
/// **UI/UX:**
/// - Круглая форма с primary цветом
/// - Иконка камеры в центре
/// - Размер 48x48
///
class CameraButton extends StatelessWidget {
  const CameraButton({
    required this.photoCount,
    required this.onTap,
    super.key,
  });

  /// Количество выбранных фотографий
  final int photoCount;

  /// Callback при нажатии
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Круглая кнопка с иконкой камеры
          Container(
            width: 48.w,
            height: 48.w,
            margin: EdgeInsets.only(right: 8.w),
            decoration: const BoxDecoration(
              color: RishColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              color: Colors.black,
              size: 24.w,
              weight: 100,
            ),
          ),
        ],
      ),
    );
  }
}
