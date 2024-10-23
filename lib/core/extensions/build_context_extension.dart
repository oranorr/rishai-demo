import 'package:flutter/material.dart';
import 'package:rishai/core/extensions/text_style_extension.dart';

extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  RishTexts get styles => theme.extension<RishTexts>()!;

  Brightness get brightness => MediaQuery.of(this).platformBrightness;

  Size get size => MediaQuery.of(this).size;

  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  double get height => MediaQuery.of(this).size.height;

  double get width => MediaQuery.of(this).size.width;
}
