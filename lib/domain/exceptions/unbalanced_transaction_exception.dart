/// Thrown when debit and credit totals for a transaction do not match.
class UnbalancedTransactionException implements Exception {
  const UnbalancedTransactionException({required this.messageAr, this.code});

  final String messageAr;
  final String? code;

  @override
  String toString() => 'UnbalancedTransactionException: $messageAr';
}
