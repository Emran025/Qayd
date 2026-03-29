/// Thrown when a change is attempted on an immutable aggregate (e.g. settled voucher).
class ImmutableEntityException implements Exception {
  const ImmutableEntityException({required this.messageAr, this.code});

  final String messageAr;
  final String? code;

  @override
  String toString() => 'ImmutableEntityException: $messageAr';
}
