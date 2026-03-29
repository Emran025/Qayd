import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/trial_balance_line.dart';

/// Trial balance aggregate: lines per currency, plus per-currency totals and balance check.
final class TrialBalanceReport {
  const TrialBalanceReport({
    required this.lines,
    required this.currencySections,
  });

  /// All lines across all currencies.
  final List<TrialBalanceLine> lines;

  /// Per-currency audit totals.
  final Map<CurrencyCode, TrialBalanceCurrencySection> currencySections;

  /// True when all currencies are individually balanced.
  bool get isBalanced =>
      currencySections.values.every((s) => s.isBalanced);
}

/// Per-currency totals within a trial balance.
final class TrialBalanceCurrencySection {
  const TrialBalanceCurrencySection({
    required this.currency,
    required this.totalDebitMinorUnits,
    required this.totalCreditMinorUnits,
    required this.isBalanced,
    required this.imbalanceMinorUnits,
  });

  final CurrencyCode currency;
  final int totalDebitMinorUnits;
  final int totalCreditMinorUnits;
  final bool isBalanced;

  /// Zero when [isBalanced] is true; otherwise total debits minus total credits.
  final int imbalanceMinorUnits;
}
