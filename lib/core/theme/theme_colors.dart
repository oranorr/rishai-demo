import 'package:flutter/material.dart';

const darkColorScheme = ColorScheme.dark(
  primary: Color(0xffF88AF3),
  // surface: Color(0xff060327),
  surface: Color(0xff06061B),
  onPrimary: Color(0xff060327),
  secondary: Color.fromRGBO(168, 143, 241, 1),
  error: Color(0xffED544E),
  outline: Colors.transparent,
);

abstract class RishColors {
  static const Color textPrimary = Color(0xffEFEFEF);
  static const Color textSecondary = Color(0xffA8A8A8);
  static const Color inputField = Color(0xff050323);
  static const Color formBackgroun = Color(0xff242239);
  static const Color stroke = Color(0xff403D64);
  static const Color success = Color(0xff66C87B);
  static const Color warning = Color(0xffF4C700);
  static const Color primary = Color(0xFFF88AF3);
  static const Color surface = Color(0xff060327);
  static const Color protein = Color(0xff5E85ED);
  static const Color carbs = Color(0xffCFE887);
  static const Color fat = Color(0xff8B67F3);
  static const Color calories = Color(0xffF7B2D9);
}
