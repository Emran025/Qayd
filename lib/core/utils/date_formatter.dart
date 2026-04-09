import 'package:intl/intl.dart';

/// Locale-aware date formatting; defaults to Arabic locale when [locale] is null.
abstract final class DateFormatter {
  static String formatDate(DateTime date, {String locale = 'en'}) {
    return DateFormat.yMMMd(locale).format(date);
  }

  static String formatDateTime(DateTime date, {String locale = 'en'}) {
    return DateFormat.yMMMd(locale).add_Hm().format(date);
  }
}
