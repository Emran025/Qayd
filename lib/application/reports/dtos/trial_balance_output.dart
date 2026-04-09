import 'package:qayd/application/reports/dtos/trial_balance_line_dto.dart';

class TrialBalanceOutput {
  const TrialBalanceOutput({
    required this.lines,
    required this.currencySections,
    required this.isOverallBalanced,
    required this.title,
    required this.companyName,
    required this.fromDate,
    required this.toDate,
  });

  final List<TrialBalanceLineDto> lines;
  final Map<String, TrialBalanceCurrencySectionDto> currencySections;
  final bool isOverallBalanced;
  final String title;
  final String companyName;
  final DateTime fromDate;
  final DateTime toDate;
}

class TrialBalanceCurrencySectionDto {
  const TrialBalanceCurrencySectionDto({
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDigits,
    required this.openingDebitMinorUnits,
    required this.openingCreditMinorUnits,
    required this.periodDebitMinorUnits,
    required this.periodCreditMinorUnits,
    required this.closingDebitMinorUnits,
    required this.closingCreditMinorUnits,
    required this.isBalanced,
    required this.imbalanceMinorUnits,
  });

  final String currencyCode;
  final String currencySymbol;
  final int currencyDigits;

  final int openingDebitMinorUnits;
  final int openingCreditMinorUnits;

  final int periodDebitMinorUnits;
  final int periodCreditMinorUnits;

  final int closingDebitMinorUnits;
  final int closingCreditMinorUnits;

  final bool isBalanced;
  final int imbalanceMinorUnits;
}
