import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qayd/application/reports/dtos/trial_balance_line_dto.dart';
import 'package:qayd/application/reports/dtos/trial_balance_output.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:qayd/data/pdf/pdf_numerical_styling.dart';
import 'package:qayd/core/utils/currency_util.dart';

/// Professional PDF generator for Trial Balance reports.
///
/// Uses the unified Qayd brand palette:
///   Navy   #0F2741
///   Gold   #C9A227
///   Muted  #64748B
///   Header #8FAADC
final class TrialBalancePdfGenerator {
  const TrialBalancePdfGenerator();

  // ── Brand palette ──────────────────────────────────────────────────────
  static final PdfColor _navy = PdfColor.fromInt(0xFF0F2741);
  static final PdfColor _gold = PdfColor.fromInt(0xFFC9A227);
  static final PdfColor _muted = PdfColor.fromInt(0xFF64748B);

  Future<Uint8List> generate(
    TrialBalanceOutput report,
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
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildHeader(arabicFont, report, logoImage),
        footer: (context) => _buildFooter(arabicFont, context, report),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildInfoSection(arabicFont, report),
          pw.SizedBox(height: 14),
          _buildTable(arabicFont, report),
          pw.SizedBox(height: 14),
          _buildSummaryCards(arabicFont, report),
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
    TrialBalanceOutput report,
    pw.ImageProvider? logoImage,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE8EDF3),
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
          // ── Right: Arabic info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  report.title,
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
                  'Trial Balance — نظام السندات المالية المشفّرة',
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

          // ── Center: Logo badge
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

  pw.Widget _buildInfoSection(
    pw.Font font,
    TrialBalanceOutput report,
  ) {
    final dateFmt = intl.DateFormat('yyyy-MM-dd');
    final fromStr = dateFmt.format(report.fromDate);
    final toStr = dateFmt.format(report.toDate);
    final dateStr = 'من $fromStr إلى $toStr';
    final genAt = intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final borderColor = PdfColor.fromInt(0xFFCBD5E1);

    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _infoLine(font, 'اسم الشركة:', report.companyName),
                    pw.SizedBox(height: 4),
                    _infoLine(font, 'الفترة:', dateStr),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _infoLine(font, 'تاريخ الإصدار:', genAt),
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

  // Report Summary Badges removed as per UI matching
  // ══════════════════════════════════════════════════════════════════════════
  // ══════════════════════════════════════════════════════════════════════════
  // ── MAIN DATA TABLE ────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildTable(pw.Font font, TrialBalanceOutput report) {
    // Grouping lines by accountId
    final groups = <String, List<TrialBalanceLineDto>>{};
    for (final line in report.lines) {
      if (!groups.containsKey(line.accountId)) {
        groups[line.accountId] = [];
      }
      groups[line.accountId]!.add(line);
    }

    return pw.Table(
      border:
          pw.TableBorder.all(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FixedColumnWidth(40),
        2: pw.FlexColumnWidth(2.5),
        3: pw.FlexColumnWidth(2.5),
        4: pw.FlexColumnWidth(2.5),
      },
      children: [
        // ── Header row ──────────────────────────────────────────────────
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF0F2741)), // _navy
          children: [
            _headerCell(font, 'الحساب'),
            _headerCell(font, 'العملة'),
            _headerCell(font, 'الأرصدة الافتتاحية',
                subHeaders: ['مدين', 'دائن']),
            _headerCell(font, 'حركة الفترة', subHeaders: ['مدين', 'دائن']),
            _headerCell(font, 'الأرصدة الختامية', subHeaders: ['مدين', 'دائن']),
          ],
        ),
        // ── Data rows ───────────────────────────────────────────────────
        ...groups.values.map((group) {
          final first = group.first;
          final isBold = first.isParent || first.accountLevel == 0;
          final indent = (first.accountLevel * 10).toDouble();

          return pw.TableRow(
            decoration: first.isParent
                ? const pw.BoxDecoration(color: PdfColors.grey50)
                : null,
            children: [
              // 1. Merged Account Info Formatted
              pw.Container(
                alignment: pw.Alignment.centerRight,
                padding: pw.EdgeInsets.only(
                  right: indent,
                  left: 5,
                  top: 4,
                  bottom: 4,
                ),
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      if (first.accountCode.isNotEmpty)
                        pw.TextSpan(
                          text: '[${first.accountCode}] ',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 7,
                            color: _muted,
                          ),
                        ),
                      pw.TextSpan(
                        text: first.accountName,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 8,
                          fontWeight: isBold
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
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    decoration: l == group.last
                        ? null
                        : const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                color: PdfColor.fromInt(0xFFCBD5E1),
                                width: 0.5,
                              ),
                            ),
                          ),
                    child: pw.Text(
                      CurrencyUtil.getArabicName(l.currencyCode).replaceAll('﷼', 'ريال'),
                      style:
                          pw.TextStyle(font: font, fontSize: 7, color: _muted),
                    ),
                  );
                }).toList(),
              ),

              // 3. Opening Column
              _buildGroupedDualColumn(
                font,
                group,
                (l) => l.openingDebitMinorUnits,
                (l) => l.openingCreditMinorUnits,
                isBold,
              ),

              // 4. Period Column
              _buildGroupedDualColumn(
                font,
                group,
                (l) => l.periodDebitMinorUnits,
                (l) => l.periodCreditMinorUnits,
                isBold,
              ),

              // 5. Closing Column
              _buildGroupedDualColumn(
                font,
                group,
                (l) => l.closingDebitMinorUnits,
                (l) => l.closingCreditMinorUnits,
                isBold,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildGroupedDualColumn(
    pw.Font font,
    List<TrialBalanceLineDto> group,
    int Function(TrialBalanceLineDto) getDebit,
    int Function(TrialBalanceLineDto) getCredit,
    bool isBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: group.map((l) {
        final hasBorder = l != group.last;
        return pw.Container(
          decoration: hasBorder
              ? const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColor.fromInt(0xFFCBD5E1),
                      width: 0.5,
                    ),
                  ),
                )
              : null,
          child: _dualCell(
            font,
            getDebit(l),
            getCredit(l),
            l.currencyDigits,
            isBold: isBold,
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── CURRENCY TOTALS ────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildSummaryCards(pw.Font font, TrialBalanceOutput report) {
    if (report.currencySections.isEmpty) return pw.SizedBox();

    return pw.Column(
      children: report.currencySections.values.map((s) {
        final isBalanced = s.isBalanced;
        final statusColor = isBalanced
            ? PdfColor.fromInt(0xFF059669) // Emerald 600
            : PdfColor.fromInt(0xFFDC2626); // Error Red
        final debitColor = PdfColor.fromInt(0xFF16A34A);
        final creditColor = PdfColor.fromInt(0xFFDC2626);

        pw.Widget _cardSummaryRow(
            String label, int debit, int credit, bool isBold) {
          return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(children: [
                pw.SizedBox(
                    width: 60,
                    child: pw.Text(
                      label,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: isBold ? 11 : 10,
                        fontWeight:
                            isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                        color: _navy,
                      ),
                    )),
                pw.Expanded(child: pw.SizedBox()),
                pw.Row(children: [
                  pw.Text('دائن',
                      style: pw.TextStyle(
                          font: font, fontSize: 8, color: debitColor)),
                  pw.RichText(
                    text: buildPdfNumericalScaledSpan(
                      _formatMoney(debit, s.currencyDigits),
                      pw.TextStyle(
                        font: font,
                        fontSize: isBold ? 10 : 9,
                        fontWeight:
                            isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                        color: _navy,
                      ),
                    ),
                  ),
                ]),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Container(
                      width: 0.5, height: 12, color: PdfColors.grey300),
                ),
                pw.Row(children: [
                  pw.Text('مدين',
                      style: pw.TextStyle(
                          font: font, fontSize: 8, color: creditColor)),
                  pw.RichText(
                    text: buildPdfNumericalScaledSpan(
                      _formatMoney(credit, s.currencyDigits),
                      pw.TextStyle(
                        font: font,
                        fontSize: isBold ? 10 : 9,
                        fontWeight:
                            isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                        color: _navy,
                      ),
                    ),
                  ),
                ]),
              ]));
        }

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
                decoration: pw.BoxDecoration(
                  color: isBalanced
                      ? PdfColor.fromInt(0xFFECFDF5) // Emerald 50
                      : PdfColor.fromInt(0xFFFEF2F2), // Red 50
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(9),
                    topRight: pw.Radius.circular(9),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'خلاصة ميزان المراجعة — ${CurrencyUtil.getArabicName(s.currencyCode).replaceAll('﷼', 'ريال')}',
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
                              border:
                                  pw.Border.all(color: statusColor, width: 0.5),
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
                    pw.Divider(height: 0, thickness: 0.5, color: statusColor),
                  ],
                ),
              ),

              // ── Card Body ──
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  children: [
                    _cardSummaryRow('الافتتاحي', s.openingDebitMinorUnits,
                        s.openingCreditMinorUnits, false),
                    pw.SizedBox(height: 4),
                    _cardSummaryRow('الحركة', s.periodDebitMinorUnits,
                        s.periodCreditMinorUnits, false),
                    pw.SizedBox(height: 8),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                    pw.SizedBox(height: 8),
                    _cardSummaryRow('الختامي', s.closingDebitMinorUnits,
                        s.closingCreditMinorUnits, true),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── FOOTER ─────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildFooter(
    pw.Font font,
    pw.Context context,
    TrialBalanceOutput report,
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
          pw.Row(
            children: report.currencySections.values
                .map((s) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 12),
                      child: pw.Text(
                        '${CurrencyUtil.getArabicName(s.currencyCode).replaceAll('﷼', 'ريال')}: ${_formatMoney(s.closingDebitMinorUnits, s.currencyDigits)} / ${_formatMoney(s.closingCreditMinorUnits, s.currencyDigits)}',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: s.isBalanced ? _navy : PdfColors.red700,
                        ),
                      ),
                    ))
                .toList(),
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
  // ── TABLE CELLS ────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _headerCell(
    pw.Font font,
    String text, {
    List<String>? subHeaders,
  }) {
    final textColor = PdfColors.white;
    final debitColor =
        PdfColor.fromInt(0xFF16A34A); // scheme.tertiary equivalents
    final creditColor =
        PdfColor.fromInt(0xFFDC2626); // scheme.error equivalents
    // final subBgColor =
    //     PdfColor.fromInt(0xFFE2E8F0); // scheme.surfaceContainerHighest

    if (subHeaders != null) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: _navy,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              text,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: font,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
                color: textColor,
              ),
            ),
          ),
          pw.Table(
            border: const pw.TableBorder(
              top: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFCBD5E1), width: 0.5),
              verticalInside: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFCBD5E1), width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      subHeaders[0],
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 7,
                        color: debitColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      subHeaders[1],
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 7,
                        color: creditColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }
    return pw.Container(
      alignment: pw.Alignment.center,
      color: _navy,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
          color: textColor,
        ),
      ),
    );
  }

  // pw.Widget _dataCell(
  //   pw.Font font,
  //   String text, {
  //   bool isBold = false,
  //   double fontSize = 8,
  //   pw.EdgeInsets? padding,
  //   pw.Alignment align = pw.Alignment.center,
  // }) {
  //   return pw.Container(
  //     alignment: align,
  //     padding: padding ?? const pw.EdgeInsets.all(4),
  //     child: pw.Text(
  //       text,
  //       style: pw.TextStyle(
  //         font: font,
  //         fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
  //         fontSize: fontSize,
  //         color: _navy,
  //       ),
  //     ),
  //   );
  // }

  pw.Widget _dualCell(
    pw.Font font,
    int debit,
    int credit,
    int digits, {
    bool isBold = false,
  }) {
    final debitColor = PdfColor.fromInt(0xFF16A34A);
    final creditColor = PdfColor.fromInt(0xFFDC2626);

    return pw.Table(
      border: const pw.TableBorder(
        verticalInside:
            pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.RichText(
                text: buildPdfNumericalScaledSpan(
                  _formatMoney(debit, digits),
                  pw.TextStyle(
                    font: font,
                    fontSize: 7,
                    fontWeight:
                        isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: debit > 0 ? debitColor : _navy,
                  ),
                ),
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.RichText(
                text: buildPdfNumericalScaledSpan(
                  _formatMoney(credit, digits),
                  pw.TextStyle(
                    font: font,
                    fontSize: 7,
                    fontWeight:
                        isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: credit > 0 ? creditColor : _navy,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
}
