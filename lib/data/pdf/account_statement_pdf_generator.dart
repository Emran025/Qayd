import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:flutter/services.dart' show rootBundle;
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

/// Generates professional account-statement PDFs matching the branded
/// Excel template layout: header bar → info section → transaction table → totals → footer.
///
/// Brand palette (identical to Excel workbook):
///   Navy   #0F2741
///   Gold   #C9A227
///   Header #8FAADC
///   Muted  #64748B
final class CairoAccountStatementPdfGenerator
    implements AccountStatementPdfGenerator {
  const CairoAccountStatementPdfGenerator();

  // ── Brand palette ──────────────────────────────────────────────────────
  static final PdfColor _navy = PdfColor.fromInt(0xFF0F2741);
  static final PdfColor _gold = PdfColor.fromInt(0xFFC9A227);
  static final PdfColor _muted = PdfColor.fromInt(0xFF64748B);
  static final PdfColor _headerBlue = PdfColor.fromInt(0xFF8FAADC);
  static final PdfColor _slate50 = PdfColor.fromInt(0xFFF8FAFC);
  static final PdfColor _slate100 = PdfColor.fromInt(0xFFF1F5F9);
  static final PdfColor _errorRed = PdfColor.fromInt(0xFFD32F2F);
  static final PdfColor _border = PdfColor.fromInt(0xFFCBD5E1);

  @override
  Future<Result<Uint8List>> buildStatementPdf(
    AccountStatementReportDto report,
  ) async {
    try {
      final font = await CairoPdfFonts.font;
      final theme = pw.ThemeData.withFont(base: font, bold: font);
      final dateFmt = DateFormat.yMMMd('ar');
      final genAt = dateFmt.format(DateTime.parse(report.generatedAtIso));

      // Load logo image from assets
      pw.ImageProvider? logoImage;
      try {
        final logoData = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {
        // Logo not available, we'll use text fallback
      }

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

      final natureAr = report.natureCode == 'debit' ? 'مدين' : 'دائن';

      // Calculate totals
      int totalDebit = 0;
      int totalCredit = 0;
      for (final line in report.lines) {
        totalDebit += line.debitMinorUnits;
        totalCredit += line.creditMinorUnits;
      }
      final netBalance =
          report.lines.isNotEmpty ? report.lines.last.balanceMinorUnits : 0;

      final doc = pw.Document(theme: theme);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(font, report, genAt, logoImage),
          footer: (context) => _buildFooter(font, report, context),
          build: (context) => [
            pw.Stack(
              children: [
                if (logoImage != null)
                  pw.Positioned.fill(
                    child: pw.Center(
                      child: pw.Opacity(
                        opacity: 0.05,
                        child: pw.Image(
                          logoImage,
                          width: 450,
                          height: 450,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.SizedBox(height: 12),

                    // ── Info Section (إلى / من) ──────────────────────────────────
                    _buildInfoSection(font, report, genAt, natureAr, periodLabel),

                    pw.SizedBox(height: 14),

                    // ── Main Transaction Table ───────────────────────────────────
                    _buildTransactionTable(font, report, dateFmt),

                    pw.SizedBox(height: 14),

                    // ── Bottom Section: Notes + Totals ───────────────────────────
                    _buildBottomSection(
                      font,
                      totalDebit: totalDebit,
                      totalCredit: totalCredit,
                      netBalance: netBalance,
                    ),

                    pw.SizedBox(height: 12),

                    // ── Currency Note ────────────────────────────────────────────
                    pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text(
                        '* في حال وجود عملات متعددة، يتم عرض الإجماليات بشكل منفصل لكل عملة.',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 7,
                          color: _errorRed,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  // ══════════════════════════════════════════════════════════════════════════
  // ── HEADER BAR ─────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildHeader(
    pw.Font font,
    AccountStatementReportDto report,
    String genAt,
    pw.ImageProvider? logoImage,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Title "كشف حساب"
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'كشف حساب',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 18,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Account Statement',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: _gold,
                ),
              ),
            ],
          ),

          // Brand + Logo
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Qayd App',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: _gold,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'تطبيق قيد',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(width: 10),
              // Logo
              if (logoImage != null)
                pw.Container(
                  width: 48,
                  height: 48,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _gold, width: 1.5),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                  ),
                )
              else
                pw.Container(
                  width: 48,
                  height: 48,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1E3D6B),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _gold, width: 1.5),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'قيد',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        color: _gold,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── INFO SECTION ──────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildInfoSection(
    pw.Font font,
    AccountStatementReportDto report,
    String genAt,
    String natureAr,
    String? periodLabel,
  ) {
    return pw.Column(
      children: [
        // Two-column info row
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Right column: "إلى:" (account info)
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _border, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _infoLine(font, 'اسم الحساب:', report.accountName),
                    pw.SizedBox(height: 4),
                    _infoLine(font, 'طبيعة الحساب:', natureAr),
                    pw.SizedBox(height: 4),
                    _infoLine(
                      font,
                      'الفترة:',
                      periodLabel ?? 'كل الحركات',
                    ),
                  ],
                ),
              ),
            ),

            pw.SizedBox(width: 12),

            // Left column: Meta info
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _border, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _infoLine(font, 'تاريخ الإصدار:', genAt),
                    pw.SizedBox(height: 4),
                    _infoLine(
                      font,
                      'رقم المرجع:',
                      report.accountId.length > 12
                          ? report.accountId.substring(0, 12)
                          : report.accountId,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.BarcodeWidget(
                          barcode: Barcode.qrCode(),
                          data: report.accountId,
                          width: 42,
                          height: 42,
                          drawText: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _infoLine(pw.Font font, String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 9, color: _navy),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: _muted,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.right,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── TRANSACTION TABLE ──────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildTransactionTable(
    pw.Font font,
    AccountStatementReportDto report,
    DateFormat dateFmt,
  ) {
    final headerStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromInt(0xFF000000),
    );
    final cellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      color: PdfColor.fromInt(0xFF000000),
    );

    return pw.TableHelper.fromTextArray(
      context: null,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerDecoration: pw.BoxDecoration(color: _headerBlue),
      headerStyle: headerStyle,
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      cellStyle: cellStyle,
      cellHeight: 22,
      headerHeight: 28,
      columnWidths: {
        0: const pw.FlexColumnWidth(2.0), // التاريخ
        1: const pw.FlexColumnWidth(3.0), // البيان
        2: const pw.FlexColumnWidth(1.5), // رقم السند
        3: const pw.FlexColumnWidth(2.0), // مدين
        4: const pw.FlexColumnWidth(2.0), // دائن
        5: const pw.FlexColumnWidth(2.0), // الرصيد
      },
      headers: ['التاريخ', 'البيان', 'رقم السند', 'مدين', 'دائن', 'الرصيد'],
      data: [
        ...report.lines.map((l) {
          final d = dateFmt.format(DateTime.parse(l.dateIso));
          final debit = l.debitMinorUnits > 0
              ? MoneyFormatter.formatDecimal(l.debitMinorUnits / 100)
              : '—';
          final credit = l.creditMinorUnits > 0
              ? MoneyFormatter.formatDecimal(l.creditMinorUnits / 100)
              : '—';
          final bal = MoneyFormatter.formatDecimal(l.balanceMinorUnits / 100);
          final desc = l.description.isEmpty ? '—' : l.description;
          final vId = l.voucherId.length > 10
              ? '${l.voucherId.substring(0, 8)}…'
              : l.voucherId;

          return [d, desc, vId, debit, credit, bal];
        }),
        // Add empty rows to fill up to minimum
        ...List.generate(
          (7 - report.lines.length).clamp(0, 7),
          (_) => ['', '', '', '', '', ''],
        ),
      ],
      oddRowDecoration: pw.BoxDecoration(color: _slate100),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── BOTTOM SECTION (Notes + Totals) ────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildBottomSection(
    pw.Font font, {
    required int totalDebit,
    required int totalCredit,
    required int netBalance,
  }) {
    final debitStr = MoneyFormatter.formatDecimal(totalDebit / 100);
    final creditStr = MoneyFormatter.formatDecimal(totalCredit / 100);
    final balStr = MoneyFormatter.formatDecimal(netBalance / 100);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Notes section (right side in RTL)
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'شكراً لتعاملكم معنا!',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy,
                ),
                textAlign: pw.TextAlign.right,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'يرجى مراجعة الأرصدة والتأكد من صحتها.',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: _muted,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ],
          ),
        ),

        pw.SizedBox(width: 20),

        // Totals section (left side in RTL)
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            children: [
              // Subtotal debit
              _totalsRow(font, 'إجمالي المدين', debitStr, false),
              pw.SizedBox(height: 3),
              // Subtotal credit
              _totalsRow(font, 'إجمالي الدائن', creditStr, false),
              pw.SizedBox(height: 3),
              // Net balance (bold total row)
              _totalsRow(font, 'الرصيد الصافي', balStr, true),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _totalsRow(
    pw.Font font,
    String label,
    String value,
    bool isTotalRow,
  ) {
    final decoration = isTotalRow
        ? pw.BoxDecoration(
            color: _slate50,
            border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
          )
        : const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColors.grey300,
                width: 0.5,
                style: pw.BorderStyle.dotted,
              ),
            ),
          );

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: decoration,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: _navy,
              fontWeight: isTotalRow ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
            textAlign: pw.TextAlign.left,
          ),
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: _navy,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── FOOTER ─────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildFooter(
    pw.Font font,
    AccountStatementReportDto report,
    pw.Context context,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 7, color: _muted),
          ),
          pw.Text(
            'تم إنشاء هذا الكشف بواسطة تطبيق قيد — Qayd App',
            style: pw.TextStyle(font: font, fontSize: 7, color: _muted),
          ),
        ],
      ),
    );
  }
}
