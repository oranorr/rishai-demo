import 'package:flutter/material.dart';

extension PageControllerExtension on PageController {
  Future<void> rAnimate(int page) async {
    await animateToPage(page, duration: Durations.short4, curve: Curves.ease);
  }
}
