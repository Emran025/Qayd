/// Thrown when a monetary amount is zero, negative, or otherwise invalid.
class InvalidAmountException implements Exception {
  const InvalidAmountException({required this.messageAr, this.code});

  final String messageAr;
  final String? code;

  @override
  String toString() => 'InvalidAmountException: $messageAr';
}
