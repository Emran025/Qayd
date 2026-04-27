import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';

/// One row in a trial balance report, containing hierarchical metadata and
/// six balance columns (Opening, Period Movement, Closing) for both Debit and Credit.
final class TrialBalanceLine {
  const TrialBalanceLine({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountLevel,
    required this.isParent,
    required this.currency,
    required this.classification,
    required this.openingDebitMinorUnits,
    required this.openingCreditMinorUnits,
    required this.periodDebitMinorUnits,
    required this.periodCreditMinorUnits,
    required this.closingDebitMinorUnits,
    required this.closingCreditMinorUnits,
  });

  final AccountId accountId;
  final String accountCode;
  final String accountName;
  final int accountLevel;
  final bool isParent;
  final CurrencyCode currency;
  final AccountClassification classification;

  // Opening Balance
  final int openingDebitMinorUnits;
  final int openingCreditMinorUnits;

  // Period Movement
  final int periodDebitMinorUnits;
  final int periodCreditMinorUnits;

  // Closing Balance
  final int closingDebitMinorUnits;
  final int closingCreditMinorUnits;

  /// Helper to calculate the net signed movement (positive for debit, negative for credit).
  int get netMovementMinorUnits =>
      periodDebitMinorUnits - periodCreditMinorUnits;

  /// Helper to calculate the net signed closing balance.
  int get netClosingMinorUnits =>
      closingDebitMinorUnits - closingCreditMinorUnits;
}
