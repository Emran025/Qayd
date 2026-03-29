/// Thrown when an account cannot be deleted or deactivated due to balance or structure.
class AccountDeletionException implements Exception {
  const AccountDeletionException({required this.messageAr, this.code});

  final String messageAr;
  final String? code;

  @override
  String toString() => 'AccountDeletionException: $messageAr';
}
