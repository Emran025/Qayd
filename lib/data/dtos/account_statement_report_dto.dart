class AccountStatementReportDto {
  const AccountStatementReportDto({
    required this.accountId,
    required this.accountName,
    required this.natureCode,
    required this.lines,
    required this.generatedAtIso,
    this.periodFromIso,
    this.periodToIso,
    this.finalBalancesByCurrency = const {},
  });

  final String accountId;
  final String accountName;

  /// `debit` | `credit` (matches application statement output).
  final String natureCode;
  final List<AccountStatementLineReportDto> lines;
  final String generatedAtIso;
  final String? periodFromIso;
  final String? periodToIso;

  /// Aggregated balances per currency for the summary section.
  final Map<String, int> finalBalancesByCurrency;
}

class AccountStatementLineReportDto {
  const AccountStatementLineReportDto({
    required this.dateIso,
    required this.description,
    required this.debitMinorUnits,
    required this.creditMinorUnits,
    required this.balanceMinorUnits,
    required this.voucherId,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDigits,
  });

  final String dateIso;
  final String description;
  final int debitMinorUnits;
  final int creditMinorUnits;
  final int balanceMinorUnits;
  final String voucherId;
  final String currencyCode;
  final String currencySymbol;
  final int currencyDigits;
}
