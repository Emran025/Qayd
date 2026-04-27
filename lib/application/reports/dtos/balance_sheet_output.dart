import 'package:qayd/domain/value_objects/account_classification.dart';

/// Single line in a Balance Sheet report.
class BalanceSheetLineDto {
  const BalanceSheetLineDto({
    required this.accountId,
    required this.parentId,
    required this.accountCode,
    required this.accountName,
    required this.level,
    required this.isParent,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDigits,
    required this.balanceMinorUnits,
    required this.classification,
  });

  final String accountId;
  final String? parentId;
  final String accountCode;
  final String accountName;
  final int level;
  final bool isParent;
  final String currencyCode;
  final String currencySymbol;
  final int currencyDigits;
  final int balanceMinorUnits;
  final AccountClassification classification;
}

/// Currency-grouped totals for the Balance Sheet.
class BalanceSheetCurrencySectionDto {
  const BalanceSheetCurrencySectionDto({
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDigits,
    required this.totalAssetsMinorUnits,
    required this.totalLiabilitiesMinorUnits,
    required this.totalEquityMinorUnits,
    required this.isBalanced,
  });

  final String currencyCode;
  final String currencySymbol;
  final int currencyDigits;
  final int totalAssetsMinorUnits;
  final int totalLiabilitiesMinorUnits;
  final int totalEquityMinorUnits;
  final bool isBalanced;
}

/// Full Balance Sheet report output.
class BalanceSheetOutput {
  const BalanceSheetOutput({
    required this.atDate,
    required this.title,
    required this.companyName,
    required this.lines,
    required this.currencySections,
  });

  final DateTime atDate;
  final String title;
  final String companyName;
  final List<BalanceSheetLineDto> lines;
  final Map<String, BalanceSheetCurrencySectionDto> currencySections;
}
