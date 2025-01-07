import 'package:intl/intl.dart';

extension DateFormatExtension on DateTime {
  String formatAsDayString() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (isSameDate(today)) {
      return 'Today';
    } else if (isSameDate(yesterday)) {
      return 'Yesterday';
    } else {
      final dateFormat = DateFormat('EEE, MMM d');
      return dateFormat.format(this);
    }
  }

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
