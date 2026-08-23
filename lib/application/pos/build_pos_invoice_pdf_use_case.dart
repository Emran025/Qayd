import 'dart:typed_data';

import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_invoice.dart';
import 'package:qayd/domain/entities/pos_sales_report.dart';
import 'package:qayd/domain/services/pos_invoice_pdf_generator.dart';

final class BuildPosInvoicePdfUseCase {
  const BuildPosInvoicePdfUseCase({required PosInvoicePdfGenerator generator})
      : _generator = generator;

  final PosInvoicePdfGenerator _generator;

  Future<Result<Uint8List>> forInvoice(PosInvoice invoice) =>
      _generator.buildInvoicePdf(invoice);

  Future<Result<Uint8List>> forSalesReport(PosSalesReport report) =>
      _generator.buildSalesReportPdf(report);
}
