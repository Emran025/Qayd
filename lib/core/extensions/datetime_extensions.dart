extension DateTimeExtensions on DateTime {
  bool isSameCalendarDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
