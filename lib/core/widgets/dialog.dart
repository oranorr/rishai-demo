import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';

class RishiDialog {
  static void showCustomDialog(
    BuildContext context, {
    required DialogType type,
    required ActionDialogType? actionDialogType,
    required VoidCallback? action,
    final bool? isDissmissable,
    final String? text,
  }) {
    showGeneralDialog(
      context: context,
      barrierLabel: "",
      barrierDismissible: isDissmissable ?? true,
      barrierColor: const Color(0xff1717253d).withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
          child: Center(
            child: type == DialogType.actionful
                ? _buildActionfulDialog(
                    context: context,
                    actionDialogType: actionDialogType!,
                    action: action!,
                  )
                : type == DialogType.info
                    ? _buildWarningDialog(
                        text: text!, context: context, action: action)
                    : Container(),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        Tween<double> tween;
        if (anim.status == AnimationStatus.reverse) {
          tween = Tween(begin: 0, end: 1);
        } else {
          tween = Tween(begin: 0, end: 1);
        }

        return FadeTransition(
          opacity: tween.animate(anim),
          child: child,
        );
      },
    );
  }

  static Widget _buildWarningDialog({
    required String text,
    required BuildContext context,
    required VoidCallback? action,
  }) {
    return Container(
      height: 340.h,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: RishColors.stroke)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 41),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.theme.colorScheme.error,
              ),
              child: const Icon(
                Icons.warning,
                color: Colors.white,
                size: 45,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              text,
              style: context.styles.h3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            RishButton.primary(
              title: 'OK',
              action: action ??
                  () {
                    context.pop();
                  },
              enabled: true,
              isLoading: false,
              height: 48.h,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildActionfulDialog({
    required BuildContext context,
    required ActionDialogType actionDialogType,
    required VoidCallback action,
  }) {
    bool isLogout = actionDialogType == ActionDialogType.logout;
    return Container(
      height: 340.h,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: RishColors.stroke)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 41),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.theme.colorScheme.error,
              ),
              child: Icon(
                isLogout ? Icons.logout : Icons.delete_outline_rounded,
                color: Colors.white,
                size: 45,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Are you sure you want to ${isLogout ? 'log out' : 'delete your account'}?',
              style: context.styles.h3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            RishButton.primary(
              title: 'Cancel',
              action: () {
                context.pop();
              },
              enabled: true,
              isLoading: false,
              height: 48.h,
            ),
            SizedBox(height: 20.h),
            RishButton.teritary(
                height: 48.h,
                title: isLogout ? 'Log out' : 'Delete account',
                textColor: context.theme.colorScheme.error,
                action: () {
                  action();
                  context.pop();
                }),
          ],
        ),
      ),
    );
  }
}

enum ActionDialogType {
  logout,
  deleteAccount,
  warning,
  refresh,
}

enum DialogType {
  actionful,
  info,
}
