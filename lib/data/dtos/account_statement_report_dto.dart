/// Snapshot for account statement PDF (data → PDF engine boundary).
class AccountStatementReportDto {
  const AccountStatementReportDto({
    required this.accountId,
    required this.accountName,
    required this.natureCode,
    required this.lines,
    required this.generatedAtIso,
    this.periodFromIso,
    this.periodToIso,
  });

  final String accountId;
  final String accountName;

  /// `debit` | `credit` (matches application statement output).
  final String natureCode;
  final List<AccountStatementLineReportDto> lines;
  final String generatedAtIso;
  final String? periodFromIso;
  final String? periodToIso;
}

class AccountStatementLineReportDto {
  const AccountStatementLineReportDto({
    required this.dateIso,
    required this.description,
    required this.debitMinorUnits,
    required this.creditMinorUnits,
    required this.balanceMinorUnits,
    required this.voucherId,
  });

  final String dateIso;
  final String description;
  final int debitMinorUnits;
  final int creditMinorUnits;
  final int balanceMinorUnits;
  final String voucherId;
}
