/// Thrown when the same account would be debited and credited for the same amount
/// in one transaction, or when a voucher would collapse to a self-canceling pair.
class SelfCancelingEntryException implements Exception {
  const SelfCancelingEntryException({required this.messageAr, this.code});

  final String messageAr;
  final String? code;

  @override
  String toString() => 'SelfCancelingEntryException: $messageAr';
}
