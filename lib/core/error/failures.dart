/// Typed failure hierarchy for cross-layer error handling.
/// User-facing copy is Arabic ([messageAr]) per failure handling philosophy.
sealed class Failure {
  const Failure({required this.messageAr});

  final String messageAr;
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.messageAr, this.code});

  final String? code;
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.messageAr});
}

final class FileSystemFailure extends Failure {
  const FileSystemFailure({required super.messageAr});
}

final class NetworkFailure extends Failure {
  const NetworkFailure({required super.messageAr});
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.messageAr});
}
