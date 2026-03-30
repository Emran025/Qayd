/// Base type for infrastructure-level exceptions (not domain rule violations).
sealed class AppException implements Exception {
  const AppException({required this.message});

  final String message;

  @override
  String toString() => message;
}

/// Thrown when API authentication fails.
final class AuthException implements Exception {
  const AuthException(this.messageAr);
  final String messageAr;

  @override
  String toString() => 'AuthException: $messageAr';
}
