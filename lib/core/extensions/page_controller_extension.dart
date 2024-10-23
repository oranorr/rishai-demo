import 'package:flutter/material.dart';

extension PageControllerExtension on PageController {
  rAnimate(int page) {
    animateToPage(page, duration: Durations.short4, curve: Curves.ease);
  }
}
