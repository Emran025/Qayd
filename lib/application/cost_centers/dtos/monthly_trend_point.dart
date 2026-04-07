/// A single monthly data point for the cost center trend chart.
final class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.monthKey,
    required this.totalMinor,
  });

  /// Month in 'YYYY-MM' format (e.g. '2026-04').
  final String monthKey;

  /// Total confirmed voucher amount for this month in minor units.
  final int totalMinor;

  /// Short Arabic month label for chart axes.
  String get shortLabel {
    final parts = monthKey.split('-');
    if (parts.length < 2) return monthKey;
    final month = int.tryParse(parts[1]) ?? 0;
    const names = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    if (month < 1 || month > 12) return monthKey;
    return names[month - 1];
  }
}
