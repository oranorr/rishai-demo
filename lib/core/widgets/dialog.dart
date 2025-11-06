// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/services/pefs/prefs_repository.dart';
import 'package:rishai/core/theme/theme_colors.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/features/settings/domain/other_legal_texts_repo.dart';
import 'package:rishai/features/whoop/presentation/bloc/whoop_bloc.dart';

class RishiDialog {
  static Future<void> showCustomDialog(
    BuildContext context, {
    required DialogType type,
    required ActionDialogType? actionDialogType,
    required VoidCallback? action,
    bool? isDissmissable,
    String? text,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: '',
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
                        text: text!,
                        context: context,
                        action: action,
                      )
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

  static Future<void> whoopDisclaimer(
    BuildContext context, {
    String? text,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: '',
      barrierColor: const Color(0xff1717253d).withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              decoration: BoxDecoration(
                color: context.theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: RishColors.stroke),
              ),
              child: Padding(
                padding: EdgeInsets.zero,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  children: [
                    Text(
                      'Disclaimer',
                      style: context.styles.h2,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    Text(
                      LegalTextsRepo().shortDisclaimer,
                      style: context.styles.regularMedium,
                      // textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    RishButton.primary(
                      title: 'Accept',
                      enabled: true,
                      isLoading: false,
                      action: () async {
                        await prefsRepo.disclaimerAccpeted();
                        context.pop();
                        whoopBloc.add(WhoopConnectEvent(context));
                      },
                    ),
                  ],
                ),
              ),
            ),
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

  static Future<void> infoPopup(
    BuildContext context,
    String text,
  ) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: '',
      barrierDismissible: true,
      barrierColor: const Color(0xff1717253d).withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
          child: Center(
            child: Container(
              // height: ,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              decoration: BoxDecoration(
                color: context.theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: RishColors.stroke),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16).copyWith(top: 16, bottom: 16),
                child: Scrollbar(
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      Text(
                        text,
                        style: context.styles.regularMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
        border: Border.all(color: RishColors.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 41),
        child: Column(
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

  /// [showPermissionDeniedDialog] Показывает диалог, когда доступ к камере/галерее запрещен
  ///
  /// Показывает диалог с сообщением о том, что доступ запрещен и нужно разрешить
  /// в настройках приложения. Имеет две кнопки: Cancel и Go to Settings.
  ///
  /// **Параметры:**
  /// - context: Контекст для показа диалога
  /// - permissionType: Тип разрешения ('camera' или 'gallery') для кастомизации сообщения
  static Future<void> showPermissionDeniedDialog(
    BuildContext context, {
    String permissionType = 'camera or gallery',
  }) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: '',
      barrierDismissible: true,
      barrierColor: const Color(0xff1717253d).withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
          child: Center(
            child: _buildPermissionDeniedDialog(
              context: context,
              permissionType: permissionType,
            ),
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

  static Widget _buildPermissionDeniedDialog({
    required BuildContext context,
    required String permissionType,
  }) {
    return Container(
      height: 340.h,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: RishColors.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 41),
        child: Column(
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
                Icons.lock_outline_rounded,
                color: Colors.white,
                size: 45,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Access Denied',
              style: context.styles.h3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'Access to $permissionType is denied. Please enable it in device settings.',
              style: context.styles.regularMedium.copyWith(
                color: RishColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            RishButton.primary(
              title: 'Go to Settings',
              action: () async {
                context.pop();
                // Открываем настройки приложения
                await _openAppSettings(context);
              },
              enabled: true,
              isLoading: false,
              height: 48.h,
            ),
            SizedBox(height: 12.h),
            RishButton.teritary(
              height: 48.h,
              title: 'Cancel',
              textColor: RishColors.textSecondary,
              action: () {
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// [_openAppSettings] Открывает настройки приложения для изменения разрешений
  ///
  /// Использует permission_handler.openAppSettings() для открытия настроек приложения
  /// на Android и iOS.
  static Future<void> _openAppSettings(BuildContext context) async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  /// [showAddMealsConfirmationDialog] Показывает диалог подтверждения добавления блюд в дневник
  ///
  /// Показывает диалог с подтверждением перед добавлением выбранных блюд.
  /// Автоматически формирует текст в зависимости от количества блюд (meal vs meals).
  ///
  /// **Параметры:**
  /// - context: Контекст для показа диалога
  /// - mealsCount: Количество выбранных блюд
  /// - action: Callback при подтверждении добавления
  static Future<void> showAddMealsConfirmationDialog(
    BuildContext context, {
    required int mealsCount,
    required VoidCallback action,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: '',
      barrierDismissible: true,
      barrierColor: const Color(0xff1717253d).withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
          child: Center(
            child: _buildAddMealsConfirmationDialog(
              context: context,
              mealsCount: mealsCount,
              action: action,
            ),
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

  /// [_buildAddMealsConfirmationDialog] Строит виджет диалога подтверждения добавления блюд
  ///
  /// Создает диалог с иконкой, текстом подтверждения и двумя кнопками:
  /// - Cancel (основная кнопка) - закрывает диалог
  /// - Add to diary (тертиарная кнопка) - подтверждает добавление
  ///
  /// **UI/UX:**
  /// - Следует Apple HIG для диалогов подтверждения
  /// - Использует нейтральную иконку (restaurant_menu) вместо предупреждающей
  /// - Правильная плюрализация текста в зависимости от количества блюд
  static Widget _buildAddMealsConfirmationDialog({
    required BuildContext context,
    required int mealsCount,
    required VoidCallback action,
  }) {
    // [mealsText] Формируем текст с правильной плюрализацией
    final mealsText = mealsCount == 1 ? 'meal' : 'meals';
    final confirmationText =
        'Are you sure you want to add $mealsCount $mealsText to diary?';

    return Container(
      height: 340.h,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: RishColors.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 41),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.theme.colorScheme.primary,
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Colors.white,
                size: 45,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              confirmationText,
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
              title: 'Add to diary',
              textColor: context.theme.colorScheme.primary,
              action: () {
                action();
                context.pop();
              },
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
        border: Border.all(color: RishColors.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 41),
        child: Column(
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
              },
            ),
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
