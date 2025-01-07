import 'package:flutter/material.dart';
import 'package:rishai/core/constants/theme_consts.dart';
import 'package:rishai/core/theme/theme_colors.dart';

class RishInputDecorationTheme extends InputDecorationTheme {
  RishInputDecorationTheme()
      : super(
          border: voyBorderDefault,
          enabledBorder: voyBorderDefault,
          focusedBorder: voyFocusedBorder,
          disabledBorder: voyBorderDefault,
          errorBorder: voyErrorBorder,
        );
  static final OutlineInputBorder voyBorderDefault = OutlineInputBorder(
    borderRadius: ThemeConstants.borderRadius,
    borderSide: const BorderSide(
      color: RishColors.stroke,
    ),
  );

  static final OutlineInputBorder voyFocusedBorder = OutlineInputBorder(
    borderRadius: ThemeConstants.borderRadius,
    borderSide: const BorderSide(
      color: RishColors.stroke,
    ),
  );

  static final OutlineInputBorder voyErrorBorder = OutlineInputBorder(
    borderRadius: ThemeConstants.borderRadius,
    borderSide: BorderSide(
      color: darkColorScheme.error,
    ),
  );
}
