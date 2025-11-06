import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';

class RishButton extends StatefulWidget {
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
  State<RishButton> createState() => _RishButtonState();
}

class _RishButtonState extends State<RishButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !widget.enabled
          ? () {}
          : widget.isLoading ?? false
              ? () {}
              : widget.action,
      // onTap: isLoading ?? false ? () {} : action,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.enabled ? widget.backgroundColor : RishColors.stroke,
          border: widget.needsBorder
              ? Border.all(
                  color:
                      widget.borderColor ?? context.theme.colorScheme.primary,
                )
              : null,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style:
                    context.styles.boldLarge.copyWith(color: widget.textColor),
              ),
              if (widget.isLoading ?? false) ...[
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
