import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';

class RishButton extends StatelessWidget {
  const RishButton({
    required this.title,
    required this.backgroundColor,
    required this.needsBorder,
    required this.textColor,
    required this.action,
    super.key,
    this.enabled = true,
    this.height = 58,
    this.width = double.infinity,
    this.isLoading = false,
    this.radius = 24,
    this.borderColor,
  });

  factory RishButton.primary({
    required String title,
    required bool enabled,
    required bool isLoading,
    required VoidCallback action,
    double? height,
  }) {
    return RishButton(
      title: title,
      backgroundColor: RishColors.primary,
      needsBorder: false,
      textColor: RishColors.surface,
      action: action,
      height: height ?? 58.h,
      enabled: enabled,
      isLoading: isLoading,
    );
  }

  factory RishButton.secondary({
    required String title,
    required VoidCallback action,
    Color? textColor,
    Color? borderColor,
    double? width,
  }) {
    return RishButton(
      title: title,
      backgroundColor: Colors.transparent,
      needsBorder: true,
      textColor: textColor ?? RishColors.primary,
      action: action,
      height: 58.h,
      borderColor: borderColor,
      width: width,
    );
  }

  factory RishButton.teritary({
    required String title,
    required VoidCallback action,
    Color? textColor,
    double? height,
  }) {
    return RishButton(
      title: title,
      backgroundColor: Colors.transparent,
      needsBorder: false,
      textColor: textColor ?? RishColors.primary,
      action: action,
      height: height ?? 58.h,
    );
  }
  final String title;
  final double? height;
  final double? width;
  final bool? isLoading;
  final bool enabled;
  final Color backgroundColor;
  final bool needsBorder;
  final Color textColor;
  final double radius;
  final VoidCallback action;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !enabled
          ? () {}
          : isLoading ?? false
              ? () {}
              : action,
      // onTap: isLoading ?? false ? () {} : action,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: enabled ? backgroundColor : RishColors.stroke,
          border: needsBorder
              ? Border.all(
                  color: borderColor ?? context.theme.colorScheme.primary,
                )
              : null,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: context.styles.boldLarge.copyWith(color: textColor),
              ),
              if (isLoading ?? false) ...[
                SizedBox(width: 8.h),
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    color: RishColors.formBackgroun,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
