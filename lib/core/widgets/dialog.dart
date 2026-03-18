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

  /// [infoPopup] Показывает информационный попап с текстом и опциональным заголовком
  ///
  /// Показывает диалог с информационным текстом. Если передан заголовок,
  /// он отображается перед текстом в более крупном стиле.
  ///
  /// **Параметры:**
  /// - context: Контекст для показа диалога
  /// - text: Текст для отображения в попапе
  /// - title: Опциональный заголовок, который отображается перед текстом
  static Future<void> infoPopup(
    BuildContext context,
    String text, {
    String? title,
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
                      // [title] Если заголовок передан, отображаем его перед текстом
                      if (title != null) ...[
                        Text(
                          title,
                          style: context.styles.boldLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                      ],
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
      height: 400.h,
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

  /// [showPermissionSettingsDialog] Показывает диалог с объяснением о необходимости разрешения
  ///
  /// Показывает popup с объяснением, что разрешения на источник у нас нет,
  /// и кнопкой для перехода в настройки. Используется при повторном нажатии
  /// на источник без разрешения.
  ///
  /// **Параметры:**
  /// - context: Контекст для показа диалога
  /// - permissionType: Тип разрешения ('camera' или 'gallery') для кастомизации сообщения
  ///
  /// **UI/UX:**
  /// - Следует Apple HIG для диалогов с призывом к действию
  /// - Использует иконку блокировки для визуального акцента
  /// - Primary action (Go to Settings) выделен как основная кнопка
  static Future<void> showPermissionSettingsDialog(
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
            child: _buildPermissionSettingsDialog(
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

  /// [_buildPermissionSettingsDialog] Строит виджет диалога для перехода в настройки
  ///
  /// Создает диалог с иконкой, объяснением о необходимости разрешения и двумя кнопками:
  /// - Cancel (тертиарная кнопка) - закрывает диалог
  /// - Go to Settings (основная кнопка) - открывает настройки приложения
  ///
  /// **UI/UX:**
  /// - Следует Apple HIG для диалогов с призывом к действию
  /// - Использует иконку блокировки (lock_outline_rounded) для визуального акцента
  /// - Primary action (Go to Settings) выделен как основная кнопка
  static Widget _buildPermissionSettingsDialog({
    required BuildContext context,
    required String permissionType,
  }) {
    // Формируем текст объяснения в зависимости от типа разрешения
    final String explanationText;
    if (permissionType == 'camera') {
      explanationText =
          'To use the camera, you need to grant permission. Please enable camera access in the app settings.';
    } else if (permissionType == 'gallery') {
      explanationText =
          'To access the gallery, you need to grant permission. Please enable photo access in the app settings.';
    } else {
      explanationText =
          'To use this feature, you need to grant permission. Please enable access in the app settings.';
    }

    return Container(
      height: 400.h,
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
                Icons.lock_outline_rounded,
                color: Colors.white,
                size: 45,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Permission Required',
              style: context.styles.h3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              explanationText,
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
      pageBuilder: (dialogContext, __, ___) {
        return PopScope(
          // [onPopInvoked] Убираем фокус при закрытии диалога через barrier
          // Это предотвращает автоматическую прокрутку к полю ввода
          onPopInvoked: (didPop) {
            if (didPop) {
              FocusScope.of(context).unfocus();
              // [primaryFocus] Дополнительно убираем фокус через FocusManager
              FocusManager.instance.primaryFocus?.unfocus();
              // [postFrameCallback] Дополнительная проверка после закрытия диалога
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FocusManager.instance.primaryFocus?.unfocus();
              });
            }
          },
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
            child: Center(
              child: _buildAddMealsConfirmationDialog(
                context: context,
                mealsCount: mealsCount,
                action: action,
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
    const confirmationText =
        'Are you sure?\nOnce you confirm you will not be able to delete the meal';

    return Container(
      // height: 400.h,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: RishColors.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 41, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
              height: 48.h,
              title: 'Confirm',
              enabled: true,
              isLoading: false,
              action: () {
                action();
                context.pop();
              },
            ),
            SizedBox(height: 12.h),
            RishButton.teritary(
              title: 'Cancel',
              action: () {
                // [unfocus] Убираем фокус с поля ввода перед закрытием диалога
                // Это предотвращает автоматическую прокрутку к полю ввода после закрытия
                FocusScope.of(context).unfocus();
                // [primaryFocus] Дополнительно убираем фокус через FocusManager
                // для более надежного снятия фокуса
                FocusManager.instance.primaryFocus?.unfocus();
                context.pop();

                // [postFrameCallback] Дополнительная проверка после закрытия диалога
                // для гарантированного снятия фокуса
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                });
              },
              textColor: context.theme.colorScheme.primary,
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

  /// [showSubscriptionRequiredDialog] Показывает диалог о необходимости подписки
  ///
  /// Показывает диалог с сообщением о том, что добавлять больше блюд за раз могут
  /// только пользователи с подпиской. Имеет две кнопки:
  /// - OK - закрывает диалог
  /// - Upgrade - переходит на экран paywall
  ///
  /// **Параметры:**
  /// - context: Контекст для показа диалога
  /// - onUpgrade: Callback для перехода на paywall
  static Future<void> showSubscriptionRequiredDialog(
    BuildContext context, {
    required VoidCallback onUpgrade,
    required String body,
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
            child: _buildSubscriptionRequiredDialog(
              context: context,
              onUpgrade: onUpgrade,
              body: body,
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

  /// [_buildSubscriptionRequiredDialog] Строит виджет диалога о необходимости подписки
  ///
  /// Создает диалог с иконкой, текстом о необходимости подписки и двумя кнопками:
  /// - OK (тертиарная кнопка) - закрывает диалог
  /// - Upgrade (основная кнопка) - переходит на paywall
  ///
  /// **UI/UX:**
  /// - Следует Apple HIG для диалогов с призывом к действию
  /// - Использует иконку подписки (workspace_premium) для визуального акцента
  /// - Primary action (Upgrade) выделен как основная кнопка
  static Widget _buildSubscriptionRequiredDialog({
    required BuildContext context,
    required VoidCallback onUpgrade,
    required String body,
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: RishColors.primary,
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 45,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Upgrade to unlock this feature',
              // body,
              style: context.styles.h3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            RishButton.primary(
              title: 'Upgrade',
              action: () {
                onUpgrade();
                // [mountedCheck] Проверяем, что виджет все еще смонтирован перед закрытием
                if (context.mounted) {
                  context.pop();
                }
              },
              enabled: true,
              isLoading: false,
              height: 48.h,
            ),
            SizedBox(height: 12.h),
            RishButton.teritary(
              height: 48.h,
              title: 'OK',
              textColor: RishColors.textSecondary,
              action: () {
                // [mountedCheck] Проверяем, что виджет все еще смонтирован перед закрытием
                if (context.mounted) {
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// [showPhotoUploadLimitDialog] Показывает диалог о лимите загрузки фотографий
  ///
  /// Показывает диалог с сообщением о том, что бесплатные пользователи могут
  /// использовать фотографию для блюда только один раз в день. Имеет две кнопки:
  /// - OK - закрывает диалог
  /// - Upgrade - переходит на экран paywall для снятия ограничений
  ///
  /// **Параметры:**
  /// - context: Контекст для показа диалога
  /// - hoursRemaining: Количество оставшихся часов до следующей загрузки
  /// - onUpgrade: Callback для перехода на paywall
  static Future<void> showPhotoUploadLimitDialog(
    BuildContext context, {
    required int hoursRemaining,
    required VoidCallback onUpgrade,
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
            child: _buildPhotoUploadLimitDialog(
              context: context,
              hoursRemaining: hoursRemaining,
              onUpgrade: onUpgrade,
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

  /// [_buildPhotoUploadLimitDialog] Строит виджет диалога о лимите использования фотографий
  ///
  /// Создает диалог с иконкой, текстом о лимите использования фото для блюд и двумя кнопками:
  /// - OK (тертиарная кнопка) - закрывает диалог
  /// - Upgrade (основная кнопка) - переходит на paywall
  ///
  /// **UI/UX:**
  /// - Следует Apple HIG для диалогов с призывом к действию
  /// - Использует иконку камеры (camera_alt) для визуального акцента
  /// - Primary action (Upgrade) выделен как основная кнопка
  static Widget _buildPhotoUploadLimitDialog({
    required BuildContext context,
    required int hoursRemaining,
    required VoidCallback onUpgrade,
  }) {
    final hoursText = hoursRemaining == 1 ? 'hour' : 'hours';
    final line1Text = 'You can capture a meal with a photo once per day';
    final line2Text = 'Please wait $hoursRemaining $hoursText';

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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: RishColors.primary,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 45,
              ),
            ),
            SizedBox(height: 24.h),
            // Строка 1: основной текст
            Text(
              line1Text,
              style: context.styles.h3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h), // Интервал между строками
            // Строка 2: текст ожидания (на размер меньше)
            Text(
              line2Text,
              style: context.styles.h3.copyWith(
                fontSize: (context.styles.h3.fontSize ?? 16) - 1,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            RishButton.primary(
              title: 'Upgrade',
              action: () {
                onUpgrade();
                context.pop();
              },
              enabled: true,
              isLoading: false,
              height: 48.h,
            ),
            SizedBox(height: 12.h),
            RishButton.teritary(
              height: 48.h,
              title: 'OK',
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
