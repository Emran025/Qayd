class AccountStatementLineDto {
  const AccountStatementLineDto({
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
