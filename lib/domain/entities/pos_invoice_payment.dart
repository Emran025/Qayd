import 'package:qayd/domain/exceptions/invalid_pos_invoice_exception.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';

enum PosPaymentMethod { cash, bank, credit, other }

/// Immutable payment event attached to a POS invoice.
final class PosInvoicePayment {
  const PosInvoicePayment({
    required this.id,
    required this.invoiceId,
    required this.accountId,
    required this.method,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.idempotencyKey,
  });

  factory PosInvoicePayment.create({
    required String id,
    required String invoiceId,
    required AccountId accountId,
    required PosPaymentMethod method,
    required Money amount,
    required CurrencyCode currency,
    required DateTime occurredAt,
    required String idempotencyKey,
  }) {
    if (id.trim().isEmpty ||
        invoiceId.trim().isEmpty ||
        idempotencyKey.trim().isEmpty) {
      throw InvalidPosInvoiceException.requiredField();
    }
    if (amount.currency != currency || amount.isZero || amount.isNegative) {
      throw InvalidPosInvoiceException.invalidPayment();
    }
    return PosInvoicePayment(
      id: id.trim(),
      invoiceId: invoiceId.trim(),
      accountId: accountId,
      method: method,
      amount: amount,
      currency: currency,
      occurredAt: occurredAt.toUtc(),
      idempotencyKey: idempotencyKey.trim(),
    );
  }

  final String id;
  final String invoiceId;
  final AccountId accountId;
  final PosPaymentMethod method;
  final Money amount;
  final CurrencyCode currency;
  final DateTime occurredAt;
  final String idempotencyKey;
}
