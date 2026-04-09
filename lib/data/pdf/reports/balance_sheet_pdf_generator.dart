import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qayd/application/reports/dtos/balance_sheet_output.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';
import 'package:intl/intl.dart' as intl;

/// Professional PDF generator for Balance Sheet reports.
///
/// Follows the same brand palette as [CairoAccountStatementPdfGenerator]:
///   Navy   #0F2741
///   Gold   #C9A227
///   Muted  #64748B
final class BalanceSheetPdfGenerator {
  const BalanceSheetPdfGenerator();

  // ── Brand palette ──────────────────────────────────────────────────────
  static final PdfColor _navy = PdfColor.fromInt(0xFF0F2741);
  static final PdfColor _gold = PdfColor.fromInt(0xFFC9A227);
  static final PdfColor _muted = PdfColor.fromInt(0xFF64748B);
  static final PdfColor _border = PdfColor.fromInt(0xFFCBD5E1);
  static final PdfColor _sectionBg = PdfColor.fromInt(0xFFF1F5F9);

  Future<Uint8List> generate(
    BalanceSheetOutput report,
    pw.Font arabicFont,
  ) async {
    // ── Load logo ──────────────────────────────────────────────────────
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      // Fallback to text if logo unavailable
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(arabicFont, report, logoImage),
        footer: (context) => _buildFooter(arabicFont, context),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildInfoBar(arabicFont, report),
          pw.SizedBox(height: 16),
          _buildSection(
            arabicFont,
            'الأصول',
            'Assets',
            report.lines.where((l) => _isAsset(l.classification)).toList(),
          ),
          pw.SizedBox(height: 12),
          _buildSection(
            arabicFont,
            'الخصوم',
            'Liabilities',
            report.lines.where((l) => _isLiability(l.classification)).toList(),
          ),
          pw.SizedBox(height: 12),
          _buildSection(
            arabicFont,
            'حقوق الملكية',
            'Equity',
            report.lines.where((l) => _isEquity(l.classification)).toList(),
          ),
          pw.SizedBox(height: 20),
          _buildSummary(arabicFont, report),
        ],
      ),
    );

    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── HEADER ─────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildHeader(
    pw.Font font,
    BalanceSheetOutput report,
    pw.ImageProvider? logoImage,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Report title (right in RTL)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                report.title,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 18,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Balance Sheet',
                style: pw.TextStyle(font: font, fontSize: 8, color: _gold),
              ),
            ],
          ),

          // Logo + brand (left in RTL)
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
              if (logoImage != null)
                pw.Container(
                  width: 44,
                  height: 44,
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
                  width: 44,
                  height: 44,
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
  // ── INFO BAR ───────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildInfoBar(pw.Font font, BalanceSheetOutput report) {
    final dateFmt = intl.DateFormat.yMMMd('ar');
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _infoCell(font, 'الجهة:', report.companyName),
          _infoCell(font, 'التاريخ:', dateFmt.format(report.atDate)),
          _infoCell(
            font,
            'تاريخ الإصدار:',
            intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
          ),
        ],
      ),
    );
  }

  pw.Widget _infoCell(pw.Font font, String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(font: font, fontSize: 9, color: _navy),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: _muted,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── SECTION (Assets / Liabilities / Equity) ────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildSection(
    pw.Font font,
    String titleAr,
    String titleEn,
    List<BalanceSheetLineDto> lines,
  ) {
    if (lines.isEmpty) return pw.SizedBox();

    // Grouping lines by accountId
    final groups = <String, List<BalanceSheetLineDto>>{};
    for (final line in lines) {
      if (!groups.containsKey(line.accountId)) {
        groups[line.accountId] = [];
      }
      groups[line.accountId]!.add(line);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Section header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _sectionBg,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: _border, width: 0.5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                titleAr,
                style: pw.TextStyle(
                  font: font,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: _navy,
                ),
              ),
              pw.Text(
                titleEn,
                style: pw.TextStyle(font: font, fontSize: 8, color: _muted),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),

        // Account lines summary table
        pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.Table(
            border: pw.TableBorder.all(color: _border, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(2),
            },
            children: [
              // Table header
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF0F2741)), // _navy
                children: [
                  _tableHeaderCell(font, 'الحساب'),
                  _tableHeaderCell(font, 'العملة'),
                  _tableHeaderCell(font, 'الرصيد'),
                ],
              ),
              // Data rows grouped by account
              ...groups.values.map((group) {
                final first = group.first;
                final isParent = first.isParent;
                final indent = (first.level * 12).toDouble();

                return pw.TableRow(
                  decoration: isParent
                      ? const pw.BoxDecoration(color: PdfColors.grey50)
                      : null,
                  children: [
                    // 1. Merged Account Info Formatted
                    pw.Container(
                      alignment: pw.Alignment.centerRight,
                      padding: pw.EdgeInsets.only(
                        right: indent,
                        left: 4,
                        top: 5,
                        bottom: 5,
                      ),
                      child: pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            if (first.accountCode.isNotEmpty)
                              pw.TextSpan(
                                text: '[${first.accountCode}] ',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 6,
                                  color: _muted,
                                ),
                              ),
                            pw.TextSpan(
                              text: first.accountName,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 8,
                                fontWeight: isParent
                                    ? pw.FontWeight.bold
                                    : pw.FontWeight.normal,
                                color: _navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Currencies Column
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: group.map((l) {
                        return pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.symmetric(vertical: 5),
                          decoration: l == group.last
                              ? null
                              : pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom: pw.BorderSide(
                                      color: _border,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                          child: pw.Text(
                            l.currencyCode,
                            style: pw.TextStyle(
                                font: font, fontSize: 7, color: _muted),
                          ),
                        );
                      }).toList(),
                    ),

                    // 3. Balances Column
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: group.map((l) {
                        final hasBorder = l != group.last;
                        return pw.Container(
                          alignment: pw.Alignment.centerLeft,
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 6,
                          ),
                          decoration: hasBorder
                              ? pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom: pw.BorderSide(
                                      color: _border,
                                      width: 0.5,
                                    ),
                                  ),
                                )
                              : null,
                          child: pw.Text(
                            _formatMoney(l.balanceMinorUnits, l.currencyDigits),
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 8,
                              fontWeight: isParent
                                  ? pw.FontWeight.bold
                                  : pw.FontWeight.normal,
                              color: l.balanceMinorUnits < 0
                                  ? PdfColors.red700
                                  : _navy,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              }),
            ],
          ),
        )
      ],
    );
  }

  pw.Widget _tableHeaderCell(pw.Font font, String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      color: _navy,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── SUMMARY ────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildSummary(pw.Font font, BalanceSheetOutput report) {
    if (report.currencySections.isEmpty) return pw.SizedBox();

    return pw.Column(
      children: report.currencySections.values.map((s) {
        final isBalanced = s.isBalanced;
        final statusColor = isBalanced
            ? PdfColor.fromInt(0xFF059669) // Emerald 600
            : PdfColor.fromInt(0xFFDC2626); // Error Red

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: statusColor, width: 0.8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── Card Header ──
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: isBalanced
                      ? PdfColor.fromInt(0xFFECFDF5) // Emerald 50
                      : PdfColor.fromInt(0xFFFEF2F2), // Red 50
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(9),
                    topRight: pw.Radius.circular(9),
                  ),
                  border: pw.Border(
                    bottom: pw.BorderSide(color: statusColor, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ملخص الإجماليات — ${s.currencyCode}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    // Pill
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: statusColor, width: 0.5),
                      ),
                      child: pw.Text(
                        isBalanced ? 'متوازن ✓' : 'غير متوازن',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card Body ──
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  children: [
                    _summaryRow(font, 'إجمالي الأصول', s.totalAssetsMinorUnits,
                        s.currencyDigits),
                    pw.SizedBox(height: 4),
                    _summaryRow(font, 'إجمالي الخصوم',
                        s.totalLiabilitiesMinorUnits, s.currencyDigits),
                    pw.SizedBox(height: 4),
                    _summaryRow(font, 'حقوق الملكية', s.totalEquityMinorUnits,
                        s.currencyDigits),
                    pw.SizedBox(height: 8),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'صافي الخصوم والملكية',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                        pw.Text(
                          _formatMoney(
                              s.totalLiabilitiesMinorUnits +
                                  s.totalEquityMinorUnits,
                              s.currencyDigits),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _summaryRow(pw.Font font, String label, int amount, int digits) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          _formatMoney(amount, digits),
          style: pw.TextStyle(font: font, fontSize: 9, color: _navy),
        ),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: _navy,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── FOOTER ─────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildFooter(pw.Font font, pw.Context context) {
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
            'تم إنشاء هذا التقرير بواسطة تطبيق قيد — Qayd App',
            style: pw.TextStyle(font: font, fontSize: 7, color: _muted),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── HELPERS ────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  String _formatMoney(int minorUnits, int digits) {
    if (minorUnits == 0) return '-';
    num divisor = 1;
    for (var i = 0; i < digits; i++) {
      divisor *= 10;
    }
    return MoneyFormatter.formatDecimal(
      minorUnits / divisor,
      minimumFractionDigits: digits,
      maximumFractionDigits: digits,
    );
  }

  static bool _isAsset(AccountClassification c) =>
      c == AccountClassification.liquidAssets ||
      c == AccountClassification.receivables ||
      c == AccountClassification.fixedProfitableAssets ||
      c == AccountClassification.fixedDepreciableAssets;

  static bool _isLiability(AccountClassification c) =>
      c == AccountClassification.payables ||
      c == AccountClassification.settlements ||
      c == AccountClassification.clearingRemittances;

  static bool _isEquity(AccountClassification c) =>
      c == AccountClassification.personalExpenses ||
      c == AccountClassification.personalRevenues ||
      c == AccountClassification.remittanceFees;
}
