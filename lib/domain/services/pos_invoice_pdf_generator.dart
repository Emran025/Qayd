import 'dart:typed_data';

import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_invoice.dart';
import 'package:qayd/domain/entities/pos_sales_report.dart';

abstract interface class PosInvoicePdfGenerator {
  Future<Result<Uint8List>> buildInvoicePdf(PosInvoice invoice);

  Future<Result<Uint8List>> buildSalesReportPdf(PosSalesReport report);
}
