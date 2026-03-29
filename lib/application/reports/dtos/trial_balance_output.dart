import 'package:qayd/application/reports/dtos/trial_balance_line_dto.dart';

class TrialBalanceOutput {
  const TrialBalanceOutput({
    required this.lines,
    required this.currencySections,
    required this.isOverallBalanced,
  });

  final List<TrialBalanceLineDto> lines;
  final Map<String, TrialBalanceCurrencySectionDto> currencySections;
  final bool isOverallBalanced;
}

class TrialBalanceCurrencySectionDto {
  const TrialBalanceCurrencySectionDto({
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDigits,
    required this.totalDebitMinorUnits,
    required this.totalCreditMinorUnits,
    required this.isBalanced,
    required this.imbalanceMinorUnits,
  });

  final String currencyCode;
  final String currencySymbol;
  final int currencyDigits;
  final int totalDebitMinorUnits;
  final int totalCreditMinorUnits;
  final bool isBalanced;
  final int imbalanceMinorUnits;
}
