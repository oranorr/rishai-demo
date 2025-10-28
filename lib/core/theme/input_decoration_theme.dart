import 'package:flutter/material.dart';
import 'package:rishai/core/constants/theme_consts.dart';
import 'package:rishai/core/theme/theme_colors.dart';

// [RishInputDecorationTheme] Класс для создания кастомной темы InputDecoration
// Наследуется от InputDecorationThemeData для совместимости с новой версией Flutter
class RishInputDecorationTheme extends InputDecorationThemeData {
  RishInputDecorationTheme()
      : super(
          border: voyBorderDefault,
          enabledBorder: voyBorderDefault,
          focusedBorder: voyFocusedBorder,
          disabledBorder: voyBorderDefault,
          errorBorder: voyErrorBorder,
        );

  // [voyBorderDefault] Стандартный border для текстовых полей
  static final OutlineInputBorder voyBorderDefault = OutlineInputBorder(
    borderRadius: ThemeConstants.borderRadius,
    borderSide: const BorderSide(
      color: RishColors.stroke,
    ),
  );

  // [voyFocusedBorder] Border для текстовых полей в фокусе
  static final OutlineInputBorder voyFocusedBorder = OutlineInputBorder(
    borderRadius: ThemeConstants.borderRadius,
    borderSide: const BorderSide(
      color: RishColors.stroke,
    ),
  );

  // [voyErrorBorder] Border для текстовых полей с ошибкой
  static final OutlineInputBorder voyErrorBorder = OutlineInputBorder(
    borderRadius: ThemeConstants.borderRadius,
    borderSide: BorderSide(
      color: darkColorScheme.error,
    ),
  );
}
