import 'package:flutter/material.dart';
import 'package:rishai/core/theme/theme_colors.dart';

class RishTextStyle extends TextStyle {
  const RishTextStyle.font({
    super.fontSize,
    super.height,
    FontWeight? fontWeight,
    Color? color,
    super.decoration,
  }) : super(
          inherit: false,
          color: color ?? Colors.white,
          fontFamily: 'ProximaNova',
          fontWeight: fontWeight ?? AppFontWeight.regular,
          textBaseline: TextBaseline.alphabetic,
        );
  const RishTextStyle.numbers({
    super.fontSize,
    super.height,
    FontWeight? fontWeight,
    Color? color,
    super.decoration,
  }) : super(
          inherit: false,
          color: color ?? RishColors.textPrimary,
          fontFamily: 'DinPro',
          fontWeight: fontWeight ?? AppFontWeight.regular,
          textBaseline: TextBaseline.alphabetic,
        );
}

class AppFontWeight {
  AppFontWeight._();
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight bold = FontWeight.w700;
}

TextStyle large(
  FontWeight fontWeight, [
  Color? color,
  TextDecoration? decoration,
]) =>
    RishTextStyle.font(
      fontSize: 18,
      height: 28 / 18,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
    );

TextStyle medium(
  FontWeight fontWeight, [
  Color? color,
  TextDecoration? decoration,
]) =>
    RishTextStyle.font(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
    );

TextStyle small(
  FontWeight fontWeight, [
  Color? color,
  TextDecoration? decoration,
]) =>
    RishTextStyle.font(
      fontSize: 14,
      height: 22 / 14,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
    );

TextStyle header(
  double fontSize,
  double height, [
  Color? color,
  TextDecoration? decoration,
]) =>
    RishTextStyle.font(
      fontSize: fontSize,
      height: height,
      fontWeight: AppFontWeight.bold,
      color: RishColors.textPrimary,
      decoration: decoration,
    );

TextStyle numbers(
  double fontSize,
  double height, [
  Color? color,
  TextDecoration? decoration,
]) =>
    RishTextStyle.font(
      fontSize: fontSize,
      height: height,
      fontWeight: AppFontWeight.bold,
      color: color,
      decoration: decoration,
    );
