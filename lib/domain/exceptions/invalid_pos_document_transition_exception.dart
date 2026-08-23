import 'package:qayd/presentation/l10n/app_strings.dart';

/// Raised when a POS document attempts a forbidden lifecycle transition.
final class InvalidPosDocumentTransitionException implements Exception {
  const InvalidPosDocumentTransitionException({
    required this.from,
    required this.to,
    required this.messageAr,
    this.code,
  });

  final String from;
  final String to;
  final String messageAr;
  final String? code;

  factory InvalidPosDocumentTransitionException.forbidden({
    required String from,
    required String to,
  }) {
    return InvalidPosDocumentTransitionException(
      from: from,
      to: to,
      messageAr: AppStrings.posDocumentTransitionInvalid,
      code: 'pos_document_transition_invalid',
    );
  }

  @override
  String toString() =>
      'InvalidPosDocumentTransitionException: $from -> $to';
}
