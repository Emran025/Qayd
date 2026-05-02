import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:qayd/core/error/failures.dart' show UnexpectedFailure;
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/dtos/voucher_report_dto.dart';
import 'package:qayd/data/pdf/cairo_pdf_fonts.dart';
import 'package:qayd/data/pdf/voucher_pdf_generator.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qayd/core/utils/currency_util.dart';
import 'package:qayd/data/pdf/pdf_numerical_styling.dart';

/// Professional financial voucher PDF matching the Galal Nasser Exchange format.
///
/// Layout: RTL, Cairo font.
/// Rules per user spec:
///   - App name + logo in header
///   - Intermediary shown as origin for tripartite
///   - No manager signature
///   - QR barcode for each transaction
///   - Non-tripartite: single-party only (no second client row)
final class CairoVoucherPdfGenerator implements VoucherPdfGenerator {
  const CairoVoucherPdfGenerator();

  // ── Brand palette ─────────────────────────────────────────────────────────
  static final _navy = PdfColor.fromInt(0xFF0F2741);
  static final _gold = PdfColor.fromInt(0xFFC9A227);
  static final _emerald = PdfColor.fromInt(0xFF047857);
  static final _muted = PdfColor.fromInt(0xFF64748B);
  static final _border = PdfColor.fromInt(0xFFCBD5E1);
  static final _headerBg = PdfColor.fromInt(0xFFE8EDF3);
  static final _error = PdfColor.fromInt(0xFFDC2626);

  @override
  Future<Result<Uint8List>> buildVoucherPdf(VoucherReportDto report) async {
    try {
      // 1. Load assets on main thread
      final fontData = await rootBundle.load(CairoPdfFonts.asset);
      final fontBytes = fontData.buffer.asUint8List();

      Uint8List? logoBytes;
      try {
        final logoData = await rootBundle.load('assets/images/logo.png');
        logoBytes = logoData.buffer.asUint8List();
      } catch (_) {}

      // 2. Fetch shared preferences values on main thread since SharedPreferences needs to be accessed here
      final prefs = InjectionContainer.sharedPreferences;
      final customHeaderTitle =
          prefs.getString('pdf_header_title') ?? 'قيد — المحاسبة الشخصية';
      final customHeaderSubtitle = prefs.getString('pdf_header_subtitle') ??
          'نظام السندات المالية المشفّرة';
      final customFooterText = prefs.getString('pdf_footer_text') ??
          'المصدر: تطبيق قيد للمحاسبة الشخصية';

      final labelVoucherNo =
          prefs.getString('pdf_label_voucher_no') ?? 'رقم السند:';
      final labelDate = prefs.getString('pdf_label_date') ?? 'التاريخ:';
      final labelFrom = prefs.getString('pdf_label_from') ?? 'من حساب العميل:';
      final labelDescription =
          prefs.getString('pdf_label_description') ?? 'البيان:';

      final mediatorName = prefs.getString('pdf_mediator_name') ??
          prefs.getString('company_name') ??
          'نظام قيد المالي';

      // 3. Run PDF generation in an Isolate
      return await Isolate.run(() async {
        final font = pw.Font.ttf(fontBytes.buffer.asByteData());
        final theme = pw.ThemeData.withFont(base: font, bold: font);

        final isReceipt = report.typeCode == 'receipt';
        final accent = isReceipt ? _emerald : _gold;
        final typeAr = isReceipt ? 'سند قبض' : 'سند صرف';

        // Safe date parsing for pre-formatted strings
        DateTime safeParse(String iso, DateTime fallback) {
          try {
            return DateTime.parse(iso);
          } catch (_) {
            return fallback;
          }
        }

        final dateFmt = DateFormat('dd/MM/yyyy');
        final dateStr =
            _notEmpty(report.dateIso) && report.dateIso.contains('/')
                ? report.dateIso
                : dateFmt.format(safeParse(report.dateIso, DateTime.now()));

        final createdFmt = DateFormat('hh:mm:ss a  dd/MM/yyyy');
        final createdStr = _notEmpty(report.createdAtIso) &&
                (report.createdAtIso.contains('/') ||
                    report.createdAtIso.contains(':'))
            ? report.createdAtIso
            : createdFmt.format(safeParse(report.createdAtIso, DateTime.now()));

        final divisor = math.pow(10, report.currencyDigits).toDouble();
        final amount = report.amountMinorUnits / divisor;
        final fmt = report.currencyDigits > 0
            ? NumberFormat('#,##0.${'0' * report.currencyDigits}', 'en')
            : NumberFormat('#,##0', 'en');
        final amountStr =
            '${fmt.format(amount)} ${CurrencyUtil.getArabicName(report.currencyCode).replaceAll('﷼', 'ريال')}';

        final qrPayload = report.qrData ?? report.voucherId;

        pw.ImageProvider? logoImage;
        if (logoBytes != null) {
          logoImage = pw.MemoryImage(logoBytes);
        }

        // Title logic
        final titleAr = _buildTitle(report, typeAr);

        final doc = pw.Document(theme: theme);

        doc.addPage(
          pw.Page(
            // Dynamic widget-like sizing: Height adapts to the voucher type, Width matches the Image Export (550)
            pageFormat: PdfPageFormat(550, report.isTripartite ? 680 : 580),
            textDirection: pw.TextDirection.rtl,
            margin: const pw.EdgeInsets.all(12),
            build: (ctx) => pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _border, width: 1),
              ),
              child: pw.Stack(
                alignment: pw.Alignment.topCenter,
                children: [
                  // ── WATERMARK (Back layer) ─────────────────────────────
                  if (logoImage != null)
                    pw.Positioned.fill(
                      child: pw.Align(
                        alignment: pw.Alignment.topCenter,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 150),
                          child: pw.Opacity(
                            opacity: 0.05,
                            child: pw.Image(
                              logoImage,
                              width: 350,
                              height: 350,
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── CONTENT (Front layer) ──────────────────────────────
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      // ── HEADER BAR ──────────────────────────────────────────
                      _buildHeaderBar(font, logoImage, customHeaderTitle,
                          customHeaderSubtitle),

                      // ── VOUCHER NUMBER + TITLE + DATE ───────────────────────
                      _buildTitleRow(font, report, titleAr, dateStr, accent,
                          labelVoucherNo, labelDate, mediatorName),

                      pw.SizedBox(height: 6),

                      // ── ENTRY SECTIONS ──────────────────────────────────────
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 24),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            _buildEntrySection(
                              font: font,
                              amountStr: amountStr,
                              sectionType: 'debit',
                              report: report,
                              accent: accent,
                              labelFrom: labelFrom,
                              labelDescription: labelDescription,
                            ),

                            pw.SizedBox(height: 8),

                            // Credit entry (to account) — only for tripartite
                            if (report.isTripartite)
                              _buildEntrySection(
                                font: font,
                                amountStr: amountStr,
                                sectionType: 'credit',
                                report: report,
                                accent: accent,
                                labelFrom: labelFrom,
                                labelDescription: labelDescription,
                              ),

                            pw.SizedBox(height: 14),

                            // ── SIGNATURE ROW ──────────────────────────────────
                            _buildSignatureRow(font, report),

                            pw.SizedBox(height: 14),

                            // ── FOOTER ─────────────────────────────────────────
                            _buildFooter(font, report, createdStr, qrPayload,
                                customFooterText),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        return Success(await doc.save());
      });
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('Voucher PDF Generation Error: $e');
      // ignore: avoid_print
      print('Stack Trace: $stackTrace');

      return FailureResult(
        UnexpectedFailure(messageAr: 'تعذر إنشاء ملف السند: $e'),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── HEADER BAR (Company-style) ─────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildHeaderBar(pw.Font font, pw.ImageProvider? logoImage,
      String title, String subtitle) {
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
        // mainAxisSize: pw.MainAxisSize.min,
        children: [
          // ── Right: Arabic info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 11,
                    color: _navy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  subtitle,
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

          pw.SizedBox(width: 16),

          // ── Center: Logo badge
          if (logoImage != null)
            pw.Container(
              width: 52,
              height: 52,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                shape: pw.BoxShape.circle,
              ),
              child: pw.ClipOval(
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
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
  // ── TITLE ROW (Voucher # + Title + Date) ───────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildTitleRow(
    pw.Font font,
    VoucherReportDto report,
    String titleAr,
    String dateStr,
    PdfColor accent,
    String labelVoucherNo,
    String labelDate,
    String mediatorName,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: pw.Column(
        children: [
          // Top row: voucher number + date in bordered boxes
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Voucher number box (right in RTL)
              _borderedLabel(font, labelVoucherNo, _shortId(report.voucherId)),
              // Date box (left in RTL)
              _borderedLabel(font, labelDate, dateStr),
            ],
          ),
          pw.SizedBox(height: 10),

          // Title center
          pw.Center(
            child: pw.Text(
              titleAr,
              style: pw.TextStyle(
                font: font,
                fontSize: 13,
                color: _navy,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          if (report.isTripartite)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: pw.Center(
                child: pw.Text(
                  mediatorName,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 8,
                    color: _muted,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _borderedLabel(pw.Font font, String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _navy, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: _navy,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.RichText(
            text: buildPdfNumericalScaledSpan(
              value,
              pw.TextStyle(
                font: font,
                fontSize: 10,
                color: _navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── ENTRY SECTION (Debit / Credit) ─────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildEntrySection({
    required pw.Font font,
    required String amountStr,
    required String sectionType, // 'debit' or 'credit'
    required VoucherReportDto report,
    required PdfColor accent,
    required String labelFrom,
    required String labelDescription,
  }) {
    final isDebit = sectionType == 'debit';
    final isReceipt = report.typeCode == 'receipt';

    // Determine section label and account name
    String sectionLabel;
    String accountName;
    String descriptionText;
    String notesText;

    if (report.isTripartite) {
      // Tripartite: show A (sender) and B (receiver) — mediator C is hidden.
      // Receipt leg: counterpartyName = A (sender), linkedPartyName = B (receiver).
      // Payment leg: counterpartyName = B (receiver), linkedPartyName = A (sender).
      final isReceiptLeg = report.tripartiteRole == 'receipt';
      final senderName = isReceiptLeg
          ? report.counterpartyName
          : (report.linkedPartyName ?? report.counterpartyName);
      final receiverName = isReceiptLeg
          ? (report.linkedPartyName ?? '—')
          : report.counterpartyName;

      if (isDebit) {
        // Debit = "from sender"
        sectionLabel = 'بيانات القيد (المدين) — من حساب المُرسِل:';
        accountName = senderName;
      } else {
        // Credit = "to receiver" — shows B (linkedParty), NOT the mediator C
        sectionLabel = 'بيانات القيد (الدائن) — إلى حساب المُستلِم:';
        accountName = receiverName;
      }

      descriptionText = _buildTripartiteDescription(report, isDebit);
      notesText = _buildTripartiteNotes(report, isDebit);
    } else {
      // Standard voucher: single party
      if (isReceipt) {
        sectionLabel = labelFrom;
        accountName = report.counterpartyName;
      } else {
        sectionLabel = labelFrom;
        accountName = report.counterpartyName;
      }
      descriptionText = report.description ?? '';
      notesText = report.notes ?? '';
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Entry details (right column) ──
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Section header with account name
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '$sectionLabel ',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: _navy,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.TextSpan(
                          text: accountName,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: accent,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    textAlign: pw.TextAlign.right,
                  ),

                  // Total Balance display
                  if (report.counterpartyBalances.isNotEmpty &&
                      !report.isTripartite) ...[
                    pw.SizedBox(height: 2),
                    pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: 'الرصيد الإجمالي: ',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 9,
                              color: _muted,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.TextSpan(
                            text: report.counterpartyBalances.entries.map((e) {
                              final digits = (e.key == report.currencyCode)
                                  ? report.currencyDigits
                                  : 2;
                              final divisor = math.pow(10, digits).toDouble();
                              final fmt =
                                  NumberFormat('#,##0.${'0' * digits}', 'en');
                              final value = e.value / divisor;
                              final absValue = value.abs();
                              final label = report.counterpartyNature == 'debit'
                                  ? value > 0
                                      ? 'عليكم'
                                      : 'لكم'
                                  : value < 0
                                      ? 'عليكم'
                                      : 'لكم';
                              return '${fmt.format(absValue)} ${CurrencyUtil.getArabicName(e.key).replaceAll('﷼', 'ريال')} $label'
                                  .trim();
                            }).join(' | '),
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 9,
                              color: _navy,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ],

                  // Description
                  if (descriptionText.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    _labeledLine(font, labelDescription, descriptionText),
                  ],

                  // Notes
                  if (notesText.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    _labeledLine(font, 'الملاحظات:', notesText),
                  ],

                  // Reference
                  if (_notEmpty(report.referenceNumber)) ...[
                    pw.SizedBox(height: 3),
                    _labeledLine(font, 'المرجع:', report.referenceNumber!),
                  ],
                ],
              ),
            ),
          ),
          // ── Amount box (left column) ──
          pw.Container(
            width: 90,
            padding: const pw.EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(color: _border, width: 1),
              ),
            ),
            child: pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _navy, width: 1.2),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.RichText(
                  text: buildPdfNumericalScaledSpan(
                    amountStr,
                    pw.TextStyle(
                      font: font,
                      fontSize: 9,
                      color: _navy,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _labeledLine(pw.Font font, String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label ',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: _navy,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          buildPdfNumericalScaledSpan(
            value,
            pw.TextStyle(
              font: font,
              fontSize: 9,
              color: _muted,
            ),
          ),
        ],
      ),
      textAlign: pw.TextAlign.right,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── SIGNATURE ROW ──────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildSignatureRow(pw.Font font, VoucherReportDto report) {
    final hasSenderSig = report.senderSignatureHex != null &&
        report.senderSignatureHex!.isNotEmpty;
    final hasReceiverSig = report.receiverSignatureHex != null &&
        report.receiverSignatureHex!.isNotEmpty;

    // For non-tripartite: only show client signature + QR
    // For tripartite: show client 1 + client 2 signatures
    final columns = <pw.Widget>[];

    if (report.isTripartite) {
      // Client 1 signature (counterparty - sender in receipt leg)
      columns.add(
        pw.Expanded(
          child: _signatureBox(font, '(توقيع العميل الأول)', hasSenderSig),
        ),
      );
      columns.add(pw.SizedBox(width: 8));
      // Client 2 signature (linked party - receiver in receipt leg)
      columns.add(
        pw.Expanded(
          child: _signatureBox(font, '(توقيع العميل الثاني)', hasReceiverSig),
        ),
      );
    } else {
      // Single-party: show both if signed
      columns.add(
        pw.Expanded(
          flex: 2,
          child: _signatureBox(
            font,
            report.typeCode == 'receipt'
                ? '(توقيع العميل المرسل)'
                : '(توقيع العميل المستلم)',
            report.typeCode == 'receipt' ? hasSenderSig : hasReceiverSig,
          ),
        ),
      );
      columns.add(pw.SizedBox(width: 8));
      // Digital verification
      columns.add(
        pw.Expanded(
          child: pw.Container(
            height: 70,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _border, width: 0.8),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'حالة التوقيع',
                  style: pw.TextStyle(font: font, fontSize: 7, color: _muted),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _agreementAr(report.receiverStatusCode),
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 8,
                    color: _agreementColor(report.receiverStatusCode),
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: columns,
    );
  }

  pw.Widget _signatureBox(pw.Font font, String label, bool hasSig) {
    return pw.Container(
      height: 50,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          if (hasSig)
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  ' موقّع رقمياً',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: _emerald,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          pw.Divider(color: _border, thickness: 0.5),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 8, color: _muted),
            textAlign: pw.TextAlign.center,
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
    VoucherReportDto report,
    String createdStr,
    String qrPayload,
    String footerText,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(0, 8, 0, 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // ── Left info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(
                  text: buildPdfNumericalScaledSpan(
                    'تم الإنشاء:  $createdStr',
                    pw.TextStyle(font: font, fontSize: 7.5, color: _muted),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  footerText,
                  style: pw.TextStyle(font: font, fontSize: 7.5, color: _muted),
                ),

                // Crypto info
                if (report.senderPublicKeyHex != null &&
                    report.senderPublicKeyHex!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'مفتاح المرسل: ${_truncateHex(report.senderPublicKeyHex!)}',
                    style:
                        pw.TextStyle(font: font, fontSize: 6.5, color: _muted),
                  ),
                ],
                if (report.receiverPublicKeyHex != null &&
                    report.receiverPublicKeyHex!.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'مفتاح المستلم: ${_truncateHex(report.receiverPublicKeyHex!)}',
                    style:
                        pw.TextStyle(font: font, fontSize: 6.5, color: _muted),
                  ),
                ],
              ],
            ),
          ),

          // ── QR code (right)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: qrPayload,
                width: 75,
                height: 75,
                drawText: false,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'تحقق من السند',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 7,
                  color: _muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Helpers ────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  String _buildTitle(VoucherReportDto report, String typeAr) {
    if (!report.isTripartite) return typeAr;
    return 'سند تحويل ثلاثي — إشعار للطرفين';
  }

  String _buildTripartiteDescription(VoucherReportDto report, bool isDebit) {
    final isReceiptLeg = report.tripartiteRole == 'receipt';
    final senderName = isReceiptLeg
        ? report.counterpartyName
        : (report.linkedPartyName ?? report.counterpartyName);
    final receiverName = isReceiptLeg
        ? (report.linkedPartyName ?? '—')
        : report.counterpartyName;

    if (report.isTrueTripartite) {
      if (isDebit) {
        return report.description?.isNotEmpty == true
            ? report.description!
            : 'إشعار سند تحويل ثلاثي — من المُرسِل ($senderName) إلى المُستلِم ($receiverName).';
      } else {
        return report.description?.isNotEmpty == true
            ? report.description!
            : 'إشعار سند تحويل ثلاثي — من المُرسِل ($senderName) إلى المُستلِم ($receiverName).';
      }
    } else {
      if (isDebit) {
        return report.description?.isNotEmpty == true
            ? report.description!
            : 'تحويل مالي مزدوج عبر الصندوق — خصم من حساب $senderName وإضافة إلى حساب $receiverName.';
      } else {
        return report.description?.isNotEmpty == true
            ? report.description!
            : 'تمت إضافة المبلغ إلى حساب $receiverName من حساب $senderName عبر الصندوق كتحويل مزدوج.';
      }
    }
  }

  String _buildTripartiteNotes(VoucherReportDto report, bool isDebit) {
    if (isDebit) {
      return 'يُعتبر هذا الإشعار توثيقاً رسمياً بالخصم من حساب المُرسِل.';
    } else {
      return 'يُعتبر هذا الإشعار توثيقاً رسمياً بالإضافة إلى حساب المُستلِم.';
    }
  }

  bool _notEmpty(String? s) => s != null && s.trim().isNotEmpty;

  String _shortId(String id) {
    if (id.length <= 16) return id;
    final start = id.substring(0, 8);
    final end = id.substring(id.length - 8);
    return '$start…$end';
  }

  String _truncateHex(String hex) {
    if (hex.length <= 32) return hex;
    final start = hex.substring(0, 16);
    final end = hex.substring(hex.length - 16);
    return '$start…$end';
  }

  String _agreementAr(String code) {
    return switch (code) {
      'underRequest' => 'بانتظار الموافقة',
      'accepted' => 'مقبول وموقّع',
      'rejected' => 'مرفوض',
      'unverified' => 'غير مؤكد',
      _ => code,
    };
  }

  PdfColor _agreementColor(String code) {
    return switch (code) {
      'accepted' => _emerald,
      'rejected' => _error,
      'underRequest' => _gold,
      _ => _muted,
    };
  }
}
