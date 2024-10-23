import 'package:flutter/material.dart';
import 'package:rishai/core/extensions/rish_text_style.dart';
import 'package:rishai/core/extensions/text_style_extension.dart';
import 'package:rishai/core/theme/input_decoration_theme.dart';
import 'package:rishai/core/theme/theme_colors.dart';

final class AppTheme {
  static ThemeData dark = ThemeData(
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: darkColorScheme.surface,
      brightness: Brightness.dark,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(darkColorScheme.primary),
          elevation: const WidgetStatePropertyAll(0.0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      inputDecorationTheme: RishInputDecorationTheme(),
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: Colors.transparent,
        // labelTextStyle:
      ),
      splashColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      // bottomNavigationBarTheme: BottomNavigationBarThemeData(),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0.0),
          side: WidgetStatePropertyAll(BorderSide(
            color: darkColorScheme.primary,
          )),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      )).copyWith(extensions: <ThemeExtension>[
    RishTexts(
      h1: header(32, 40 / 32),
      h2: header(24, 28 / 24),
      h3: header(20, 24 / 20),
      boldLarge: large(AppFontWeight.bold),
      boldMedium: medium(AppFontWeight.bold),
      boldSmall: small(AppFontWeight.bold),
      regularLarge: large(AppFontWeight.regular),
      regularMedium: medium(AppFontWeight.regular),
      regularSmall: small(AppFontWeight.regular),
      numsL: numbers(32, 32 / 32),
      numsM: numbers(24, 24 / 24),
      numsS: numbers(16, 16 / 16),
    ),
  ]);
}
