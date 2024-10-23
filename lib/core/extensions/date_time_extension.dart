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
      final day = this.day;
      final monthName = _getMonthName(month);
      return '${_getDayEnding(day)} of $monthName';
    }
  }

  String _getDayEnding(int day) {
    if (day > 3) {
      return '${day}th';
    } else {
      return day.toString();
    }
  }

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }
}
