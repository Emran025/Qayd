class TrialBalanceLineDto {
  const TrialBalanceLineDto({
    required this.accountId,
    required this.accountName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDigits,
    required this.debitMinorUnits,
    required this.creditMinorUnits,
  });

  final String accountId;
  final String accountName;
  final String currencyCode;
  final String currencySymbol;
  final int currencyDigits;
  final int debitMinorUnits;
  final int creditMinorUnits;
}
