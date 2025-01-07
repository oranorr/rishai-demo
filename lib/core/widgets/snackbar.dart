import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:rishai/core/key.dart';

class RishSnackbar {
  void showSnackBar(String errorMessage) {
    final snackBar = SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Error!',
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
      padding: const EdgeInsets.all(25),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xffED544E)),
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color(0xff060327),
      duration: const Duration(seconds: 3),
    );
    if (scaffoldKey.currentContext != null) {
      scaffoldKey.currentState?.showSnackBar(snackBar);
      // ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(snackBar);
    } else {
      log('CANT SHOW SNACK NOW!');
    }
  }
}
