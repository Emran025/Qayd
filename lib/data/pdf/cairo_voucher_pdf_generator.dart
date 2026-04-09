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
      final font = await CairoPdfFonts.font;
      final theme = pw.ThemeData.withFont(base: font, bold: font);

      final isReceipt = report.typeCode == 'receipt';
      final accent = isReceipt ? _emerald : _gold;
      final typeAr = isReceipt ? 'سند قبض' : 'سند صرف';

      final dateFmt = DateFormat('dd/MM/yyyy');
      final dateStr = dateFmt.format(DateTime.parse(report.dateIso));
      final createdFmt = DateFormat('hh:mm:ss a  dd/MM/yyyy');
      final createdStr = createdFmt.format(DateTime.parse(report.createdAtIso));

      final divisor = math.pow(10, report.currencyDigits).toDouble();
      final amount = report.amountMinorUnits / divisor;
      final fmt = NumberFormat('#,##0.${'0' * report.currencyDigits}', 'en');
      final amountStr = '#${fmt.format(amount)} ${report.currencyCode}#';

      final qrPayload = report.qrData ?? report.voucherId;

      // Load logo image from assets
      pw.ImageProvider? logoImage;
      try {
        final logoData = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {
        logoImage = null;
      }

      // Load Custom Brand Texts & Labels
      final prefs = InjectionContainer.sharedPreferences;
      final customHeaderTitle = prefs.getString('pdf_header_title') ?? 'قيد — المحاسبة الشخصية';
      final customHeaderSubtitle = prefs.getString('pdf_header_subtitle') ?? 'نظام السندات المالية المشفّرة';
      final customFooterText = prefs.getString('pdf_footer_text') ?? 'المصدر: تطبيق قيد للمحاسبة الشخصية';
      
      final labelVoucherNo = prefs.getString('pdf_label_voucher_no') ?? 'رقم السند:';
      final labelDate = prefs.getString('pdf_label_date') ?? 'التاريخ:';
      final labelFrom = prefs.getString('pdf_label_from') ?? 'من حساب العميل:';
      final labelDescription = prefs.getString('pdf_label_description') ?? 'البيان التفصيلي:';

      // Title logic
      final titleAr = _buildTitle(report, typeAr);

      final doc = pw.Document(theme: theme);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: pw.EdgeInsets.zero,
          build: (ctx) => pw.Stack(
            children: [
              // ── WATERMARK (Back layer) ─────────────────────────────
              if (logoImage != null)
                pw.Positioned.fill(
                  child: pw.Center(
                    child: pw.Opacity(
                      opacity: 0.05,
                      child: pw.Image(
                        logoImage,
                        width: 400,
                        height: 400,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ),

              // ── CONTENT (Front layer) ──────────────────────────────
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // ── HEADER BAR ──────────────────────────────────────────
                  _buildHeaderBar(font, logoImage, customHeaderTitle, customHeaderSubtitle),

                  // ── VOUCHER NUMBER + TITLE + DATE ───────────────────────
                  _buildTitleRow(font, report, titleAr, dateStr, accent, labelVoucherNo, labelDate),

                  pw.SizedBox(height: 6),

                  // ── ENTRY SECTIONS ──────────────────────────────────────
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 24),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        // Debit entry (from account)
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
                        _buildFooter(font, report, createdStr, qrPayload, customFooterText),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      return Success(await doc.save());
    } catch (_) {
      return const FailureResult(
        UnexpectedFailure(messageAr: 'تعذر إنشاء ملف السند.'),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── HEADER BAR (Company-style) ─────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildHeaderBar(pw.Font font, pw.ImageProvider? logoImage, String title, String subtitle) {
    return pw.Container(
      color: _headerBg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // ── Right: Arabic info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
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
              width: 56,
              height: 56,
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
              crossAxisAlignment: pw.CrossAxisAlignment.start,
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
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        ],
      ),
    );
  }

  pw.Widget _borderedLabel(pw.Font font, String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          pw.SizedBox(width: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: _navy,
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
      // Tripartite: show intermediary in origin
      final isReceiptLeg = report.tripartiteRole == 'receipt';

      if (isDebit) {
        // Debit section = "from" account
        sectionLabel = isReceiptLeg
            ? 'بيانات القيد (المدين) - من حساب العميل:'
            : 'بيانات القيد (المدين) - من حساب الوسيط:';
        accountName =
            isReceiptLeg ? report.counterpartyName : report.affectedName;
      } else {
        // Credit section = "to" account
        sectionLabel = isReceiptLeg
            ? 'بيانات القيد (الدائن) - إلى حساب الوسيط:'
            : 'بيانات القيد (الدائن) - إلى حساب العميل المستلم:';
        accountName =
            isReceiptLeg ? report.affectedName : report.counterpartyName;
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
          // ── Amount box (left column) ──
          pw.Container(
            width: 100,
            padding: const pw.EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: _border, width: 1),
              ),
            ),
            child: pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _navy, width: 1.2),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  amountStr,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: _navy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ),

          // ── Entry details (right column) ──
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(12),
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

                  // Description
                  if (descriptionText.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    _labeledLine(font, labelDescription, descriptionText),
                  ],

                  // Notes
                  if (notesText.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    _labeledLine(font, 'الملاحظات:', notesText),
                  ],

                  // Reference
                  if (_notEmpty(report.referenceNumber)) ...[
                    pw.SizedBox(height: 4),
                    _labeledLine(font, 'المرجع:', report.referenceNumber!),
                  ],
                ],
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
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
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
                pw.SizedBox(height: 4),
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
      height: 70,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          if (hasSig)
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  '✓ موقّع رقمياً',
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
          pw.SizedBox(height: 4),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
                pw.Text(
                  'تم الإنشاء:  $createdStr',
                  style: pw.TextStyle(font: font, fontSize: 7.5, color: _muted),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  footerText,
                  style: pw.TextStyle(font: font, fontSize: 7.5, color: _muted),
                ),

                // Crypto info
                if (report.senderPublicKeyHex != null &&
                    report.senderPublicKeyHex!.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'مفتاح المرسل: ${_truncateHex(report.senderPublicKeyHex!)}',
                    style:
                        pw.TextStyle(font: font, fontSize: 6.5, color: _muted),
                  ),
                ],
                if (report.receiverPublicKeyHex != null &&
                    report.receiverPublicKeyHex!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
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
                width: 64,
                height: 64,
                drawText: false,
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'تحقق من السند',
                style: pw.TextStyle(font: font, fontSize: 7, color: _muted),
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

    final isReceiptLeg = report.tripartiteRole == 'receipt';
    final legLabel =
        isReceiptLeg ? 'إشعار للطرفين' : 'إشعار قيد العميل المحوّل';
    return 'سند قيد مزدوج وإشعار قيد ($legLabel)\n- $legLabel';
  }

  String _buildTripartiteDescription(VoucherReportDto report, bool isDebit) {
    final isReceiptLeg = report.tripartiteRole == 'receipt';

    if (isDebit) {
      if (isReceiptLeg) {
        return 'تحويل مالي بنكي إلى حساب العميل المستلم: ${report.linkedPartyName ?? '—'}.';
      } else {
        return 'تحويل مالي مستلم من حساب ${report.counterpartyName}.';
      }
    } else {
      if (isReceiptLeg) {
        return report.description ?? 'تحويل مالي مستلم.';
      } else {
        return 'تحويل مالي مستلم من حساب ${report.linkedPartyName ?? '—'}.';
      }
    }
  }

  String _buildTripartiteNotes(VoucherReportDto report, bool isDebit) {
    if (isDebit) {
      return 'يعتبر هذا السند إشعاراً بالخصم من رصيد حسابكم الجاري.';
    } else {
      return 'يعتبر هذا السند إشعاراً بالإضافة إلى رصيد حسابكم الجاري كتحويل مالي مستلم.';
    }
  }

  bool _notEmpty(String? s) => s != null && s.trim().isNotEmpty;

  String _shortId(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 8)}…${id.substring(id.length - 8)}';
  }

  String _truncateHex(String hex) {
    if (hex.length <= 32) return hex;
    return '${hex.substring(0, 16)}…${hex.substring(hex.length - 16)}';
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
