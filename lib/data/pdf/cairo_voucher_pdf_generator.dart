import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:intl/intl.dart';
import 'package:qayd/core/error/failures.dart' show UnexpectedFailure;
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/data/dtos/voucher_report_dto.dart';
import 'package:qayd/data/pdf/cairo_pdf_fonts.dart';
import 'package:qayd/data/pdf/voucher_pdf_generator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Printable voucher PDF with embedded Cairo, RTL layout, and QR document id.
final class CairoVoucherPdfGenerator implements VoucherPdfGenerator {
  const CairoVoucherPdfGenerator();

  static final PdfColor _navy = PdfColor.fromInt(0xFF0F2741);
  static final PdfColor _gold = PdfColor.fromInt(0xFFC9A227);
  static final PdfColor _emerald = PdfColor.fromInt(0xFF047857);
  static final PdfColor _muted = PdfColor.fromInt(0xFF64748B);

  @override
  Future<Result<Uint8List>> buildVoucherPdf(VoucherReportDto report) async {
    try {
      final font = await CairoPdfFonts.font;
      final theme = pw.ThemeData.withFont(base: font, bold: font);
      final isReceipt = report.typeCode == 'receipt';
      final accent = isReceipt ? _emerald : _gold;
      final typeTitle = isReceipt ? 'سند قبض' : 'سند صرف';
      final dateFmt = DateFormat.yMMMd('ar');
      final dateStr = dateFmt.format(DateTime.parse(report.dateIso));
      final amountStr =
          MoneyFormatter.formatDecimal(report.amountMinorUnits / 100);
      final stateAr = _stateAr(report.stateCode);

      final doc = pw.Document(theme: theme);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 76,
                      height: 76,
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: _gold, width: 1.5),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'قيد',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 20,
                            color: _navy,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'قيد',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 20,
                            color: _navy,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: pw.BoxDecoration(
                            color: accent,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Text(
                            typeTitle,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 14,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: report.voucherId,
                      width: 80,
                      height: 80,
                      drawText: false,
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _gold, width: 1.2),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'رقم السند',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 10,
                              color: _muted,
                            ),
                          ),
                          pw.Text(
                            report.voucherId,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 11,
                              color: _navy,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Center(
                        child: pw.Text(
                          amountStr,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 28,
                            color: _navy,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Center(
                        child: pw.Text(
                          'المبلغ',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: _muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                _row(font, 'الحالة', stateAr),
                _row(font, 'التاريخ', dateStr),
                _row(font, 'الحساب المتأثر', report.affectedName),
                _row(font, 'الطرف المقابل', report.counterpartyName),
                if (report.referenceNumber != null &&
                    report.referenceNumber!.trim().isNotEmpty)
                  _row(font, 'المرجع', report.referenceNumber!.trim()),
                if (report.description != null &&
                    report.description!.trim().isNotEmpty)
                  _row(font, 'البيان', report.description!.trim()),
                if (report.notes != null && report.notes!.trim().isNotEmpty)
                  _row(font, 'ملاحظات', report.notes!.trim()),
                pw.SizedBox(height: 28),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 8),
                pw.Text(
                  'وثيقة مُصدَرة من تطبيق قيد — سجل دائم للعمليات المحاسبية.',
                  style: pw.TextStyle(font: font, fontSize: 8, color: _muted),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      return Success(await doc.save());
    } catch (_) {
      return const FailureResult(
        UnexpectedFailure(messageAr: 'تعذر إنشاء ملف السند.'),
      );
    }
  }

  pw.Widget _row(pw.Font font, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: font, fontSize: 10, color: _muted),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 11, color: _navy),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _stateAr(String code) {
    return switch (code) {
      'draft' => 'مسودة',
      'confirmed' => 'مؤكد',
      'settled' => 'مسوّى',
      _ => code,
    };
  }
}
