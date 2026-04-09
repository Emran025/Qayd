class GenerateTrialBalanceInput {
  const GenerateTrialBalanceInput({
    this.fromDate,
    this.toDate,
    this.title,
    this.companyName,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final String? title;
  final String? companyName;
}
