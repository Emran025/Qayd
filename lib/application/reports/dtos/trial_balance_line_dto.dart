class TrialBalanceLineDto {
  const TrialBalanceLineDto({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountLevel,
    required this.isParent,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDigits,
    required this.openingDebitMinorUnits,
    required this.openingCreditMinorUnits,
    required this.periodDebitMinorUnits,
    required this.periodCreditMinorUnits,
    required this.closingDebitMinorUnits,
    required this.closingCreditMinorUnits,
  });

  final String accountId;
  final String accountCode;
  final String accountName;
  final int accountLevel;
  final bool isParent;
  final String currencyCode;
  final String currencySymbol;
  final int currencyDigits;

  final int openingDebitMinorUnits;
  final int openingCreditMinorUnits;

  final int periodDebitMinorUnits;
  final int periodCreditMinorUnits;

  final int closingDebitMinorUnits;
  final int closingCreditMinorUnits;
}
