import 'package:intl/intl.dart';

/// Monetary display formatting (presentation-adjacent; kept in core per structure).
abstract final class MoneyFormatter {
  static String formatDecimal(
    num amount, {
    String locale = 'ar',
    int minimumFractionDigits = 2,
    int maximumFractionDigits = 2,
  }) {
    final format = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = minimumFractionDigits
      ..maximumFractionDigits = maximumFractionDigits;
    return format.format(amount);
  }
  static String formatWithSymbol(
    num amount,
    String symbol, {
    String locale = 'ar',
    int fractionalDigits = 2,
  }) {
    final val = formatDecimal(
      amount,
      locale: locale,
      minimumFractionDigits: fractionalDigits,
      maximumFractionDigits: fractionalDigits,
    );
    return '$val $symbol';
  }
}
