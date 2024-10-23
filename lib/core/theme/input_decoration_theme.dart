import 'package:flutter/material.dart';
import 'package:rishai/core/constants/theme_consts.dart';
import 'package:rishai/core/theme/theme_colors.dart';

class RishInputDecorationTheme extends InputDecorationTheme {
  static final OutlineInputBorder voyBorderDefault = OutlineInputBorder(
    borderRadius: ThemeConstants.borderRadius,
    borderSide: const BorderSide(
      width: ThemeConstants.borderWidth,
      color: RishColors.stroke,
    ),
  );

  static final OutlineInputBorder voyFocusedBorder = OutlineInputBorder(
    borderRadius: ThemeConstants.borderRadius,
    borderSide: const BorderSide(
        width: ThemeConstants.borderWidth, color: RishColors.stroke),
  );

  static final OutlineInputBorder voyErrorBorder = OutlineInputBorder(
    borderRadius: ThemeConstants.borderRadius,
    borderSide: BorderSide(
      width: ThemeConstants.borderWidth,
      color: darkColorScheme.error,
    ),
  );

  // static final OutlineInputBorder voyDisabledBorder = OutlineInputBorder(
  //     borderRadius: ThemeConstants.borderRadius,
  //     borderSide: BorderSide(
  //         width: ThemeConstants.borderWidth,
  //         color: HardcodedVoyagerColors.grayStroke));

  RishInputDecorationTheme()
      : super(
          border: voyBorderDefault,
          enabledBorder: voyBorderDefault,
          focusedBorder: voyFocusedBorder,
          disabledBorder: voyBorderDefault,
          errorBorder: voyErrorBorder,
        );
}
