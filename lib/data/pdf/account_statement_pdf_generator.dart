import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:intl/intl.dart';
import 'package:qayd/core/error/failures.dart' show UnexpectedFailure;
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/data/dtos/account_statement_report_dto.dart';
import 'package:qayd/data/pdf/cairo_pdf_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

abstract interface class AccountStatementPdfGenerator {
  Future<Result<Uint8List>> buildStatementPdf(AccountStatementReportDto report);
}

final class CairoAccountStatementPdfGenerator implements AccountStatementPdfGenerator {
  const CairoAccountStatementPdfGenerator();

  static final PdfColor _navy = PdfColor.fromInt(0xFF0F2741);
  static final PdfColor _gold = PdfColor.fromInt(0xFFC9A227);
  static final PdfColor _muted = PdfColor.fromInt(0xFF64748B);

  @override
  Future<Result<Uint8List>> buildStatementPdf(
    AccountStatementReportDto report,
  ) async {
    try {
      final font = await CairoPdfFonts.font;
      final theme = pw.ThemeData.withFont(base: font, bold: font);
      final dateFmt = DateFormat.yMMMd('ar');
      final genAt =
          dateFmt.format(DateTime.parse(report.generatedAtIso));

      String? periodLabel;
      if (report.periodFromIso != null || report.periodToIso != null) {
        final a = report.periodFromIso != null
            ? dateFmt.format(DateTime.parse(report.periodFromIso!))
            : '…';
        final b = report.periodToIso != null
            ? dateFmt.format(DateTime.parse(report.periodToIso!))
            : '…';
        periodLabel = '$a — $b';
      }

      final natureAr =
          report.natureCode == 'debit' ? 'مدين' : 'دائن';

      final doc = pw.Document(theme: theme);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'قيد',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 22,
                        color: _navy,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'كشف حساب',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 16,
                        color: _gold,
                      ),
                    ),
                  ],
                ),
                pw.BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: report.accountId,
                  width: 72,
                  height: 72,
                  drawText: false,
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _gold, width: 1),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _kv('اسم الحساب', report.accountName, font),
                  pw.SizedBox(height: 6),
                  _kv('طبيعة الحساب', natureAr, font),
                  pw.SizedBox(height: 6),
                  _kv(
                    'الفترة',
                    periodLabel ?? 'كل الحركات',
                    font,
                  ),
                  pw.SizedBox(height: 6),
                  _kv('تاريخ الإصدار', genAt, font),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            _tableHeader(font),
            ...report.lines.map((l) => _lineRow(l, font, dateFmt)),
          ],
        ),
      );

      return Success(await doc.save());
    } catch (_) {
      return const FailureResult(
        UnexpectedFailure(messageAr: 'تعذر إنشاء ملف كشف الحساب.'),
      );
    }
  }

  pw.Widget _kv(String label, String value, pw.Font font) {
    return pw.Row(
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
    );
  }

  pw.Widget _tableHeader(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey300,
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey500),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              'التاريخ',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'البيان',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              'مدين',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              'دائن',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              'الرصيد',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _lineRow(
    AccountStatementLineReportDto l,
    pw.Font font,
    DateFormat dateFmt,
  ) {
    final d = dateFmt.format(DateTime.parse(l.dateIso));
    final debit = l.debitMinorUnits > 0
        ? MoneyFormatter.formatDecimal(l.debitMinorUnits / 100)
        : '—';
    final credit = l.creditMinorUnits > 0
        ? MoneyFormatter.formatDecimal(l.creditMinorUnits / 100)
        : '—';
    final bal = MoneyFormatter.formatDecimal(l.balanceMinorUnits / 100);
    final desc = l.description.isEmpty ? '—' : l.description;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              d,
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              desc,
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.right,
              maxLines: 3,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              debit,
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              credit,
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              bal,
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
