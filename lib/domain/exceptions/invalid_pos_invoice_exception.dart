import 'package:qayd/presentation/l10n/app_strings.dart';

final class InvalidPosInvoiceException implements Exception {
  const InvalidPosInvoiceException._(this.messageAr, this.code);

  final String messageAr;
  final String code;

  factory InvalidPosInvoiceException.requiredField() =>
      InvalidPosInvoiceException._(
          AppStrings.posInvoiceInvalid, 'required_field');

  factory InvalidPosInvoiceException.linesRequired() =>
      InvalidPosInvoiceException._(
          AppStrings.posInvoiceLinesRequired, 'lines_required');

  factory InvalidPosInvoiceException.invalidLine() =>
      InvalidPosInvoiceException._(
          AppStrings.posInvoiceLineInvalid, 'line_invalid');

  factory InvalidPosInvoiceException.currencyMismatch() =>
      InvalidPosInvoiceException._(
          AppStrings.posStockCurrencyMismatch, 'currency_mismatch');

  factory InvalidPosInvoiceException.invalidTotals() =>
      InvalidPosInvoiceException._(
          AppStrings.posInvoiceTotalsInvalid, 'totals_invalid');

  factory InvalidPosInvoiceException.invalidPayment() =>
      InvalidPosInvoiceException._(
          AppStrings.posInvoicePaymentInvalid, 'payment_invalid');

  factory InvalidPosInvoiceException.invalidTransition() =>
      InvalidPosInvoiceException._(
          AppStrings.posInvoiceTransitionInvalid, 'transition_invalid');

  factory InvalidPosInvoiceException.signatureMismatch() =>
      InvalidPosInvoiceException._(
          AppStrings.posInvoiceSignatureInvalid, 'signature_invalid');

  @override
  String toString() => 'InvalidPosInvoiceException($code): $messageAr';
}
