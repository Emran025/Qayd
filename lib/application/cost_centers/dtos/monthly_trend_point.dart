import 'package:qayd/presentation/l10n/app_strings.dart';

/// A single monthly data point for the cost center trend chart.
final class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.monthKey,
    required this.totalsByCurrency,
  });

  /// Month in 'YYYY-MM' format (e.g. '2026-04').
  final String monthKey;

  /// Confirmed voucher totals for this month grouped by currency (minor units).
  final Map<String, int> totalsByCurrency;

  /// Short Arabic month label for chart axes.
  String get shortLabel {
    final parts = monthKey.split('-');
    if (parts.length < 2) return monthKey;
    final month = int.tryParse(parts[1]) ?? 0;
    final names = [
      AppStrings.january,
      AppStrings.february,
      AppStrings.march,
      AppStrings.april,
      AppStrings.may,
      AppStrings.june,
      AppStrings.july,
      AppStrings.august,
      AppStrings.september,
      AppStrings.october,
      AppStrings.november,
      AppStrings.december,
    ];
    if (month < 1 || month > 12) return monthKey;
    return names[month - 1];
  }
}
