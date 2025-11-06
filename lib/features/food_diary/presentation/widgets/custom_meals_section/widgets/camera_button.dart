import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/cpi.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CameraButton Widget
/// ═══════════════════════════════════════════════════════════════════════════
class AnalyzeButton extends StatelessWidget {
  const AnalyzeButton({
    required this.isEnabled,
    required this.onTap,
    required this.isLoading,
    super.key,
  });

  /// Количество выбранных фотографий
  final bool isEnabled;

  /// Флаг загрузки при отправке запроса
  final bool isLoading;

  /// Callback при нажатии
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: isLoading
          ? const RishCPI()
          : Container(
              width: 48.w,
              height: 48.w,
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                color: isEnabled ? RishColors.primary : RishColors.stroke,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.generating_tokens,
                color: Colors.black,
                size: 24.w,
                weight: 100,
              ),
            ),
    );
  }
}
