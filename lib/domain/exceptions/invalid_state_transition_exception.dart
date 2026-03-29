/// Thrown when a generic lifecycle transition is not allowed.
class InvalidStateTransitionException implements Exception {
  const InvalidStateTransitionException({required this.messageAr, this.code});

  final String messageAr;
  final String? code;

  @override
  String toString() => 'InvalidStateTransitionException: $messageAr';
}
