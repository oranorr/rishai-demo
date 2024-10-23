import 'package:flutter/material.dart';
import 'package:rishai/core/theme/theme_colors.dart';

class RishCPI extends StatefulWidget {
  const RishCPI({super.key});

  @override
  State<RishCPI> createState() => _RishCPIState();
}

class _RishCPIState extends State<RishCPI> {
  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(
      color: RishColors.primary,
      // backgroundColor: Colors.black.withOpacity(0.7),
      strokeCap: StrokeCap.round,
      strokeWidth: 3,
    );
  }
}
