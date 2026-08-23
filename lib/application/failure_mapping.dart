import 'package:qayd/core/error/failures.dart';
import 'package:qayd/domain/exceptions/account_deletion_exception.dart';
import 'package:qayd/domain/exceptions/immutable_entity_exception.dart';
import 'package:qayd/domain/exceptions/invalid_amount_exception.dart';
import 'package:qayd/domain/exceptions/invalid_pos_invoice_exception.dart';
import 'package:qayd/domain/exceptions/invalid_state_transition_exception.dart';
import 'package:qayd/domain/exceptions/invalid_voucher_transition_exception.dart';
import 'package:qayd/domain/exceptions/self_canceling_entry_exception.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

Failure failureFromDomainException(Object error) {
  if (error is InvalidPosInvoiceException) {
    return ValidationFailure(messageAr: error.messageAr, code: error.code);
  }
  if (error is InvalidAmountException) {
    return ValidationFailure(messageAr: error.messageAr, code: error.code);
  }
  if (error is InvalidStateTransitionException) {
    return ValidationFailure(messageAr: error.messageAr, code: error.code);
  }
  if (error is InvalidVoucherTransitionException) {
    return ValidationFailure(messageAr: error.messageAr);
  }
  if (error is ImmutableEntityException) {
    return ValidationFailure(messageAr: error.messageAr, code: error.code);
  }
  if (error is SelfCancelingEntryException) {
    return ValidationFailure(messageAr: error.messageAr, code: error.code);
  }
  if (error is AccountDeletionException) {
    return ValidationFailure(messageAr: error.messageAr, code: error.code);
  }
  if (error is ArgumentError) {
    return ValidationFailure(
      messageAr: error.message?.toString() ?? AppStrings.invalidData,
      code: 'argument_error',
    );
  }
  return UnexpectedFailure(
    messageAr: AppStrings.anUnexpectedErrorOccurred3,
  );
}
