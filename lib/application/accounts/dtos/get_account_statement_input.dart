class GetAccountStatementInput {
  const GetAccountStatementInput({
    required this.accountId,
    this.fromDate,
    this.toDate,
  });

  final String accountId;
  final DateTime? fromDate;
  final DateTime? toDate;
}
