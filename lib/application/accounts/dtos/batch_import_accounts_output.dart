/// Result of importing multiple root accounts from CSV rows.
class BatchImportAccountsOutput {
  const BatchImportAccountsOutput({
    required this.createdCount,
    required this.failures,
  });

  final int createdCount;
  final List<BatchImportAccountFailure> failures;
}

class BatchImportAccountFailure {
  const BatchImportAccountFailure({
    required this.lineNumber,
    required this.messageAr,
  });

  final int lineNumber;
  final String messageAr;
}
