import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:rishai/core/key.dart';
import 'package:rishai/core/theme/theme_colors.dart';

class RishSnackbar {
  void showSnackBar(
    String errorMessage, {
    bool isError = true,
  }) {
    final snackBar = SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // if (needsTitle ?? true)
          Text(
            isError ? 'Oops...' : 'Success!',
            style: TextStyle(
              fontFamily: 'ProximaNova',
              color:
                  isError ? const Color(0xffED544E) : const Color(0xff66C87B),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Text(
            errorMessage,
            style: TextStyle(
              fontFamily: 'ProximaNova',
              color:
                  isError ? const Color(0xffED544E) : const Color(0xff66C87B),
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        ],
      ),
      // animation: CurvedAnimation(parent: parent, curve: curve),
      padding: const EdgeInsets.all(25),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isError ? const Color(0xffED544E) : const Color(0xff66C87B),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color.fromRGBO(6, 3, 39, 1),
      duration: const Duration(seconds: 2),
    );
    if (scaffoldKey.currentContext != null) {
      scaffoldKey.currentState?.showSnackBar(snackBar);
      // ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(snackBar);
    } else {
      log('CANT SHOW SNACK NOW!');
    }
  }

  /// [showWarningSnackBar] Показывает предупреждающий снекбар в верхней части экрана
  /// в стиле Apple - минималистичный, ненавязчивый, с плавной анимацией
  ///
  /// Следует принципам Apple Human Interface Guidelines:
  /// - Показывается сверху для информационных уведомлений
  /// - Использует безопасные зоны (safe area)
  /// - Позволяет смахивание вверх для закрытия
  /// - Минималистичный дизайн с акцентным цветом primary
  void showWarningSnackBar({
    required String message,
  }) {
    final context = scaffoldKey.currentContext;
    if (context == null) {
      log('CANT SHOW SNACK NOW!');
      return;
    }

    // [safeAreaPadding] Получаем безопасные зоны для учета notch и status bar
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final screenHeight = mediaQuery.size.height;

    // [snackBarHeight] Компактная высота снекбара
    // padding (16 * 2 = 32) + текст (~18) = ~66
    const snackBarHeight = 66.0;

    // [bottomNavHeight] Высота нижней навигации (если есть) + FAB
    // bottomNavigationBar: 66 + floatingActionButton: 56 + отступы
    const bottomReservedSpace = 66.0 + 56.0;

    // [topPosition] Позиция сверху: safe area padding + небольшой отступ
    final topPosition = topPadding + 12.0;

    // [bottomMargin] Рассчитываем bottom margin так, чтобы снекбар был сверху
    // Учитываем все элементы внизу, чтобы избежать конфликтов
    final bottomMargin = screenHeight -
        topPosition -
        snackBarHeight -
        bottomReservedSpace -
        bottomPadding;

    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'ProximaNova',
          color: RishColors.primary,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      // [padding] Уменьшенный padding для компактности
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      // [behavior] SnackBarBehavior.floating для современного вида с отступами
      behavior: SnackBarBehavior.floating,
      // [margin] Отступы сверху для показа в верхней части экрана
      // Учитываем безопасные зоны (status bar, notch) и нижние элементы
      margin: EdgeInsets.only(
        bottom: bottomMargin.clamp(0.0, double.infinity), // Показываем сверху
        right: 16,
        left: 16,
      ),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: RishColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: const Color.fromRGBO(6, 3, 39, 0.95),
      // [duration] Длительность в стиле Apple - достаточно времени для прочтения
      duration: const Duration(milliseconds: 1800),
      // [dismissDirection] Позволяем смахивать вверх для закрытия
      // в соответствии с Apple Human Interface Guidelines
      dismissDirection: DismissDirection.up,
    );

    scaffoldKey.currentState?.showSnackBar(snackBar);
  }
}
