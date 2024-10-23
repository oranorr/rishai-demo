// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class RishTexts extends ThemeExtension<RishTexts> {
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;

  final TextStyle boldLarge;
  final TextStyle boldMedium;
  final TextStyle boldSmall;
  final TextStyle regularLarge;
  final TextStyle regularMedium;
  final TextStyle regularSmall;

  final TextStyle numsL;
  final TextStyle numsM;
  final TextStyle numsS;

  RishTexts({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.boldLarge,
    required this.boldMedium,
    required this.boldSmall,
    required this.regularLarge,
    required this.regularMedium,
    required this.regularSmall,
    required this.numsL,
    required this.numsM,
    required this.numsS,
  });

  RishTexts copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? boldLarge,
    TextStyle? boldMedium,
    TextStyle? boldSmall,
    TextStyle? regularLarge,
    TextStyle? regularMedium,
    TextStyle? regularSmall,
    TextStyle? numsL,
    TextStyle? numsM,
    TextStyle? numsS,
  }) {
    return RishTexts(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      boldLarge: boldLarge ?? this.boldLarge,
      boldMedium: boldMedium ?? this.boldMedium,
      boldSmall: boldSmall ?? this.boldSmall,
      regularLarge: regularLarge ?? this.regularLarge,
      regularMedium: regularMedium ?? this.regularMedium,
      regularSmall: regularSmall ?? this.regularSmall,
      numsL: numsL ?? this.numsL,
      numsM: numsM ?? this.numsM,
      numsS: numsS ?? this.numsS,
    );
  }

  @override
  ThemeExtension<RishTexts> lerp(
      covariant ThemeExtension<RishTexts>? other, double t) {
    if (other == null || other is! RishTexts) {
      return this;
    }

    return RishTexts(
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      boldLarge: TextStyle.lerp(boldLarge, other.boldLarge, t)!,
      boldMedium: TextStyle.lerp(boldMedium, other.boldMedium, t)!,
      boldSmall: TextStyle.lerp(boldSmall, other.boldSmall, t)!,
      regularLarge: TextStyle.lerp(regularLarge, other.regularLarge, t)!,
      regularMedium: TextStyle.lerp(regularMedium, other.regularMedium, t)!,
      regularSmall: TextStyle.lerp(regularSmall, other.regularSmall, t)!,
      numsL: TextStyle.lerp(numsL, other.numsL, t)!,
      numsM: TextStyle.lerp(numsM, other.numsM, t)!,
      numsS: TextStyle.lerp(numsS, other.numsS, t)!,
    );
  }
}
