import 'dart:typed_data';

import 'package:qayd/data/dtos/voucher_report_dto.dart';
import 'package:qayd/core/result/result.dart';

/// Renders a printable PDF for a voucher (embedded Cairo, RTL layout).
abstract interface class VoucherPdfGenerator {
  Future<Result<Uint8List>> buildVoucherPdf(VoucherReportDto report);
}
