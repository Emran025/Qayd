import 'package:qayd/presentation/l10n/app_strings.dart';

/// Raised when a POS quantity violates its domain invariant.
final class InvalidPosQuantityException implements Exception {
  const InvalidPosQuantityException({required this.messageAr, this.code});

  final String messageAr;
  final String? code;

  factory InvalidPosQuantityException.negative() {
    return InvalidPosQuantityException(
      messageAr: AppStrings.posQuantityCannotBeNegative,
      code: 'pos_quantity_negative',
    );
  }

  factory InvalidPosQuantityException.notPositive() {
    return InvalidPosQuantityException(
      messageAr: AppStrings.posQuantityMustBePositive,
      code: 'pos_quantity_not_positive',
    );
  }

  factory InvalidPosQuantityException.invalidScale() {
    return InvalidPosQuantityException(
      messageAr: AppStrings.posQuantityScaleInvalid,
      code: 'pos_quantity_scale_invalid',
    );
  }

  factory InvalidPosQuantityException.scaleMismatch() {
    return InvalidPosQuantityException(
      messageAr: AppStrings.posQuantityScaleMismatch,
      code: 'pos_quantity_scale_mismatch',
    );
  }

  factory InvalidPosQuantityException.resultNegative() {
    return InvalidPosQuantityException(
      messageAr: AppStrings.posQuantityWouldBeNegative,
      code: 'pos_quantity_result_negative',
    );
  }

  @override
  String toString() => 'InvalidPosQuantityException: $messageAr';
}
