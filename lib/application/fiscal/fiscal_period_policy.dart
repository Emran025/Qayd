import 'package:qayd/domain/entities/fiscal_period.dart';

/// Date containment and overlap rules for fiscal periods.
abstract final class FiscalPeriodPolicy {
  static bool voucherDateInClosedPeriod(
    List<FiscalPeriod> periods,
    DateTime voucherDate,
  ) {
    final d = DateTime(voucherDate.year, voucherDate.month, voucherDate.day);
    for (final p in periods) {
      if (p.status != FiscalPeriodStatus.closed) continue;
      if (p.containsCalendarDate(d)) return true;
    }
    return false;
  }

  static FiscalPeriod? periodContaining(
    List<FiscalPeriod> periods,
    DateTime voucherDate,
  ) {
    final d = DateTime(voucherDate.year, voucherDate.month, voucherDate.day);
    FiscalPeriod? best;
    for (final p in periods) {
      if (p.containsCalendarDate(d)) {
        if (best == null ||
            p.startDate.isAfter(best.startDate)) {
          best = p;
        }
      }
    }
    return best;
  }

  /// True if [range] intersects any existing period (any status).
  static bool rangeOverlapsExisting(
    List<FiscalPeriod> existing,
    DateTime start,
    DateTime end, {
    String? excludePeriodId,
  }) {
    for (final p in existing) {
      if (excludePeriodId != null && p.id == excludePeriodId) continue;
      if (p.overlapsRange(start, end)) return true;
    }
    return false;
  }

  static DateTime firstMomentAfterClosedEnd(DateTime closedEndDate) {
    final e =
        DateTime(closedEndDate.year, closedEndDate.month, closedEndDate.day);
    return e.add(const Duration(days: 1));
  }
}
