/// Base type for infrastructure-level exceptions (not domain rule violations).
sealed class AppException implements Exception {
  const AppException({required this.message});

  final String message;

  @override
  String toString() => message;
}

/// Thrown when API authentication fails.
final class AuthException extends AppException {
  const AuthException(String message) : super(message: message);

  /// Arabic message for UI display (alias for message).
  String get messageAr => message;

  @override
  String toString() => 'AuthException: $message';
}
