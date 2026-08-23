import 'dart:collection';

import 'package:qayd/domain/entities/pos_invoice.dart';
import 'package:qayd/domain/entities/pos_invoice_payment.dart';

final class PosInvoiceDetails {
  PosInvoiceDetails({
    required this.invoice,
    required List<PosInvoicePayment> payments,
  }) : payments = UnmodifiableListView(payments);

  final PosInvoice invoice;
  final List<PosInvoicePayment> payments;
}
