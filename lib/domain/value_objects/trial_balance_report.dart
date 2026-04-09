import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/date_range.dart';
import 'package:qayd/domain/value_objects/trial_balance_line.dart';

/// Advanced trial balance report containing hierarchical data,
/// metadata for presentation, and multi-column totals.
final class TrialBalanceReport {
  const TrialBalanceReport({
    required this.title,
    required this.companyName,
    required this.dateRange,
    required this.lines,
    required this.currencySections,
  });

  final String title;
  final String companyName;
  final DateRange dateRange;

  /// All lines across all currencies.
  final List<TrialBalanceLine> lines;

  /// Per-currency audit totals.
  final Map<CurrencyCode, TrialBalanceCurrencySection> currencySections;

  /// True when all currencies are individually balanced (Closing balances).
  bool get isBalanced => currencySections.values.every((s) => s.isBalanced);
}

/// Detailed per-currency totals for all columns of the trial balance.
final class TrialBalanceCurrencySection {
  const TrialBalanceCurrencySection({
    required this.currency,
    required this.openingDebitMinorUnits,
    required this.openingCreditMinorUnits,
    required this.periodDebitMinorUnits,
    required this.periodCreditMinorUnits,
    required this.closingDebitMinorUnits,
    required this.closingCreditMinorUnits,
  });

  final CurrencyCode currency;

  final int openingDebitMinorUnits;
  final int openingCreditMinorUnits;

  final int periodDebitMinorUnits;
  final int periodCreditMinorUnits;

  final int closingDebitMinorUnits;
  final int closingCreditMinorUnits;

  /// Balanced when closing debits equal closing credits.
  bool get isBalanced => closingDebitMinorUnits == closingCreditMinorUnits;

  /// Difference in closing totals.
  int get imbalanceMinorUnits =>
      closingDebitMinorUnits - closingCreditMinorUnits;
}
