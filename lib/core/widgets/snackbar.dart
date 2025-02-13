import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:rishai/core/key.dart';
import 'package:rishai/core/theme/theme_colors.dart';

class RishSnackbar {
  void showSnackBar(String errorMessage) {
    final snackBar = SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // if (needsTitle ?? true)
          const Text(
            'Oops...',
            style: TextStyle(
              fontFamily: 'ProximaNova',
              color: Color(0xffED544E),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Text(
            errorMessage,
            style: const TextStyle(
              fontFamily: 'ProximaNova',
              color: Color(0xffED544E),
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        ],
      ),
      // animation: CurvedAnimation(parent: parent, curve: curve),
      padding: const EdgeInsets.all(25),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xffED544E)),
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color.fromRGBO(6, 3, 39, 1),
      duration: const Duration(seconds: 2),
    );
    if (scaffoldKey.currentContext != null) {
      scaffoldKey.currentState?.showSnackBar(snackBar);
      // ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(snackBar);
    } else {
      log('CANT SHOW SNACK NOW!');
    }
  }

  void showWarningSnackBar({
    required String message,
  }) {
    final snackBar = SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // if (needsTitle ?? true)
          // const Text(
          //   'Oops...',
          //   style: TextStyle(
          //     fontFamily: 'ProximaNova',
          //     color: Color(0xffED544E),
          //     fontWeight: FontWeight.w700,
          //     fontSize: 18,
          //   ),
          // ),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'ProximaNova',
              color: RishColors.primary,
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        ],
      ),
      // animation: CurvedAnimation(parent: parent, curve: curve),
      padding: const EdgeInsets.all(25),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: RishColors.primary),
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color.fromRGBO(6, 3, 39, 1),
      duration: const Duration(seconds: 2),
    );
    if (scaffoldKey.currentContext != null) {
      scaffoldKey.currentState?.showSnackBar(snackBar);
      // ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(snackBar);
    } else {
      log('CANT SHOW SNACK NOW!');
    }
  }
}
