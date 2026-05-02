import 'dart:isolate';
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
import 'package:qayd/core/utils/currency_util.dart';
import 'package:qayd/data/pdf/pdf_numerical_styling.dart';

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
  static final PdfColor _headerBg = PdfColor.fromInt(0xFFE8EDF3);
  static final PdfColor _slate50 = PdfColor.fromInt(0xFFF8FAFC);
  static final PdfColor _slate100 = PdfColor.fromInt(0xFFF1F5F9);
  static final PdfColor _border = PdfColor.fromInt(0xFFCBD5E1);

  @override
  Future<Result<Uint8List>> buildStatementPdf(
    AccountStatementReportDto report,
  ) async {
    try {
      // 1. Load assets on main thread
      final fontData = await rootBundle.load(CairoPdfFonts.asset);
      final fontBytes = fontData.buffer.asUint8List();

      Uint8List? logoBytes;
      try {
        final logoData = await rootBundle.load('assets/images/logo.png');
        logoBytes = logoData.buffer.asUint8List();
      } catch (_) {
        // Logo not available, we'll use text fallback
      }

      // 2. Run PDF generation in an Isolate to prevent UI freeze on large files
      return await Isolate.run(() async {
        final font = pw.Font.ttf(fontBytes.buffer.asByteData());
        final theme = pw.ThemeData.withFont(base: font, bold: font);
        final dateFmt = DateFormat('dd/MM/yyyy');
        final genAt = dateFmt.format(DateTime.parse(report.generatedAtIso));

        pw.ImageProvider? logoImage;
        if (logoBytes != null) {
          logoImage = pw.MemoryImage(logoBytes);
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

        final natureAr = report.natureCode == 'debit' ? 'دائن' : 'مدين';

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
            pageTheme: pw.PageTheme(
              pageFormat: PdfPageFormat.a4,
              textDirection: pw.TextDirection.rtl,
              theme: theme,
              margin: const pw.EdgeInsets.all(32),
              buildBackground: (context) {
                if (logoImage != null) {
                  return pw.FullPage(
                    ignoreMargins: true,
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
                  );
                }
                return pw.SizedBox();
              },
            ),
            header: (context) => _buildHeader(font, report, genAt, logoImage),
            footer: (context) => _buildFooter(font, report, context),
            build: (context) => [
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
                finalBalances: report.finalBalancesByCurrency,
              ),
            ],
          ),
        );

        return Success(await doc.save());
      });
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('PDF Generation Error: $e');
      // ignore: avoid_print
      print('Stack Trace: $stackTrace');
      
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
    // Custom brand text from SharedPreferences (same as voucher header)
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _headerBg,
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(8),
          topRight: pw.Radius.circular(8),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // ── Right: Arabic info (company name + doc title)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'كشف الحساب',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 15,
                    color: _navy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Account Statement — نظام السندات المالية المشفّرة',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 7,
                    color: _muted,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ],
            ),
          ),

          pw.SizedBox(width: 16),

          // ── Center: Logo badge (same as voucher)
          if (logoImage != null)
            pw.Container(
              width: 52,
              height: 52,
              decoration: const pw.BoxDecoration(
                color: PdfColors.white,
                shape: pw.BoxShape.circle,
              ),
              child: pw.ClipOval(
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            )
          else
            pw.Container(
              width: 52,
              height: 52,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1E3D6B),
                shape: pw.BoxShape.circle,
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

          pw.SizedBox(width: 16),

          // ── Left: English info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Qayd — Personal Accounting',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: _navy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Encrypted Financial Voucher System',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 7,
                    color: _muted,
                  ),
                ),
              ],
            ),
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
          child: pw.RichText(
            text: buildPdfNumericalScaledSpan(
              value,
              pw.TextStyle(font: font, fontSize: 9, color: _navy),
            ),
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
        0: const pw.FlexColumnWidth(1.8), // التاريخ
        1: const pw.FlexColumnWidth(3.0), // البيان
        2: const pw.FlexColumnWidth(1.2), // العملة
        3: const pw.FlexColumnWidth(1.5), // رقم السند
        4: const pw.FlexColumnWidth(1.8), // مدين
        5: const pw.FlexColumnWidth(1.8), // دائن
      },
      headers: [
        'التاريخ',
        'البيان',
        'العملة',
        'رقم السند',
        'دائن',
        'مدين'
      ],
      data: [
        ...report.lines.map((l) {
          final d = dateFmt.format(DateTime.parse(l.dateIso));
          final divisor = l.currencyDigits == 0
              ? 1
              : (l.currencyDigits == 3
                  ? 1000
                  : 100); // Simple fallback for common cases
          final debit = l.debitMinorUnits > 0
              ? MoneyFormatter.formatDecimal(l.debitMinorUnits / divisor,
                  minimumFractionDigits: l.currencyDigits,
                  maximumFractionDigits: l.currencyDigits)
              : '—';
          final credit = l.creditMinorUnits > 0
              ? MoneyFormatter.formatDecimal(l.creditMinorUnits / divisor,
                  minimumFractionDigits: l.currencyDigits,
                  maximumFractionDigits: l.currencyDigits)
              : '—';
          final desc = l.description.isEmpty ? '—' : l.description;
          final vId = l.voucherId.length > 10
              ? '${l.voucherId.substring(0, 8)}…'
              : l.voucherId;
          final currencyName = CurrencyUtil.getArabicName(l.currencyCode)
              .replaceAll('﷼', 'ريال');

          return [d, desc, currencyName, vId, debit, credit];
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
    required Map<String, int> finalBalances,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: _navy,
            borderRadius:
                const pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
          ),
          child: pw.Text(
            'صافي الأرصدة الختامية',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.SizedBox(height: 2),
        ...finalBalances.entries.map((e) {
          final amount = e.value / 100;
          final absAmount = amount.abs();
          final label = amount < 0 ? 'عليكم' : 'لكم';
          final amountStr = MoneyFormatter.formatDecimal(absAmount);

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 2),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _slate50,
              border: pw.Border.all(color: _border, width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      label,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color:
                            amount < 0 ? PdfColors.red800 : PdfColors.green800,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.RichText(
                      text: buildPdfNumericalScaledSpan(
                        amountStr,
                        pw.TextStyle(
                            font: font,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _navy),
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      CurrencyUtil.getArabicName(e.key).replaceAll('﷼', 'ريال'),
                      style:
                          pw.TextStyle(font: font, fontSize: 10, color: _muted),
                    ),
                  ],
                ),
                pw.Text(
                  'الرصيد (${CurrencyUtil.getArabicName(e.key).replaceAll('﷼', 'ريال')})',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: _navy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
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
    final issuer = report.issuerName;
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
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
          if (issuer != null && issuer.trim().isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _headerBg,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    issuer,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 8,
                      color: _navy,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    ':الجهة المُنشِئة للكشف',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 8,
                      color: _muted,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
