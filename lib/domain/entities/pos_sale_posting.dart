import 'dart:collection';

import 'package:qayd/domain/entities/pos_accounting_posting.dart';
import 'package:qayd/domain/entities/pos_invoice.dart';
import 'package:qayd/domain/entities/pos_invoice_payment.dart';
import 'package:qayd/domain/entities/pos_stock_movement.dart';
import 'package:qayd/domain/exceptions/invalid_pos_invoice_exception.dart';

/// Complete immutable payload required to atomically post one POS sale.
final class PosSalePosting {
  PosSalePosting({
    required this.invoice,
    required List<PosStockMovement> movements,
    required List<PosAccountingPosting> postings,
    required List<PosInvoicePayment> payments,
  })  : movements = UnmodifiableListView(movements),
        postings = UnmodifiableListView(postings),
        payments = UnmodifiableListView(payments) {
    if (invoice.type != PosInvoiceType.sale) {
      throw InvalidPosInvoiceException.invalidLine();
    }
    // A full cash/credit sale has two postings (commercial + COGS).
    // A split settlement may add a second commercial posting for the due leg.
    if (this.movements.isEmpty || this.postings.length < 2) {
      throw InvalidPosInvoiceException.invalidTotals();
    }
    for (final movement in this.movements) {
      if (movement.sourceId != invoice.id ||
          movement.sourceType != 'pos_invoice' ||
          movement.direction != PosStockMovementDirection.outbound) {
        throw InvalidPosInvoiceException.invalidLine();
      }
    }
    for (final posting in this.postings) {
      if (posting.sourceId != invoice.id ||
          posting.voucher.referenceNumber != invoice.id ||
          posting.voucher.date.toUtc().year !=
              invoice.invoiceDate.toUtc().year ||
          posting.voucher.date.toUtc().month !=
              invoice.invoiceDate.toUtc().month ||
          posting.voucher.date.toUtc().day != invoice.invoiceDate.toUtc().day) {
        throw InvalidPosInvoiceException.invalidTotals();
      }
    }
    for (final payment in this.payments) {
      if (payment.invoiceId != invoice.id ||
          payment.currency != invoice.currency) {
        throw InvalidPosInvoiceException.invalidPayment();
      }
    }
  }

  final PosInvoice invoice;
  final UnmodifiableListView<PosStockMovement> movements;
  final UnmodifiableListView<PosAccountingPosting> postings;
  final UnmodifiableListView<PosInvoicePayment> payments;
}
