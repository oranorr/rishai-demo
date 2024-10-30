import 'package:flutter/foundation.dart';

double kjToKcal = 0.239006;
double kgToLbs = 2.205;

//Если возвращает false — то прила начнет тащить данные с вупа

// bool whoopDateDifference(DateTime askTime) {
//   final now = DateTime.now();
//   final diff = now.difference(askTime);
//   // print(diff);
//   return kDebugMode ? diff.inMinutes < 1 : diff.inDays <= 1;
//   // return kDebugMode ? diff.inMinutes < 50 : diff.inDays <= 1;
// }

bool recompDifference(Duration diff) {
  return kDebugMode ? diff.inMinutes > 15 : diff.inDays >= 14;
}

// bool chatIsActual(DateTime askTime) {
//   final now = DateTime.now();

//   return now.year == askTime.year &&
//       now.month == askTime.month &&
//       now.day == askTime.day;
// }

bool emptifyWhoopData = false;
