import 'dart:math' as math;
import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:intl/intl.dart';
import 'package:qayd/core/error/failures.dart' show UnexpectedFailure;
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/dtos/voucher_report_dto.dart';
import 'package:qayd/data/pdf/cairo_pdf_fonts.dart';
import 'package:qayd/data/pdf/voucher_pdf_generator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// High-fidelity neo-minimalist financial voucher PDF.
/// Layout: RTL, Cairo font, Deep Navy / Royal Gold / Emerald palette.
final class CairoVoucherPdfGenerator implements VoucherPdfGenerator {
  const CairoVoucherPdfGenerator();

  // ── Brand palette ───────────────────────────────────────────────────────
  static final _navy    = PdfColor.fromInt(0xFF0F2741);
  static final _gold    = PdfColor.fromInt(0xFFC9A227);
  static final _emerald = PdfColor.fromInt(0xFF047857);
  static final _muted   = PdfColor.fromInt(0xFF64748B);
  static final _light   = PdfColor.fromInt(0xFFF8FAFC);
  static final _border  = PdfColor.fromInt(0xFFE2E8F0);
  static final _goldLight  = PdfColor.fromInt(0xFFFDF8EC);
  static final _emeraldLight = PdfColor.fromInt(0xFFECFDF5);

  @override
  Future<Result<Uint8List>> buildVoucherPdf(VoucherReportDto report) async {
    try {
      final font  = await CairoPdfFonts.font;
      final theme = pw.ThemeData.withFont(base: font, bold: font);

      final isReceipt = report.typeCode == 'receipt';
      final accent     = isReceipt ? _emerald : _gold;
      final accentBg   = isReceipt ? _emeraldLight : _goldLight;
      final typeAr     = isReceipt ? 'سند قبض' : 'سند صرف';
      final typeEn     = isReceipt ? 'Receipt Voucher' : 'Payment Voucher';

      final dateFmt = DateFormat.yMMMMd('ar');
      final dateStr = dateFmt.format(DateTime.parse(report.dateIso));

      final divisor  = math.pow(10, report.currencyDigits).toDouble();
      final amount   = report.amountMinorUnits / divisor;
      final fmt = NumberFormat('#,##0.${'0' * report.currencyDigits}', 'en');
      final amountStr  = fmt.format(amount);
      final tafqeetStr = _tafqeet(report.amountMinorUnits, report.currencyDigits, report.currencyNameAr);

      final stateAr = _stateAr(report.stateCode);
      final qrPayload = report.qrData ?? report.voucherId;

      final doc = pw.Document(theme: theme);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: pw.EdgeInsets.zero,
          build: (ctx) => pw.Stack(
            children: [
              // ── Faint background watermark ──────────────────────────────
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: -math.pi / 5,
                    child: pw.Opacity(
                      opacity: 0.025,
                      child: pw.Text(
                        'قيد',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 220,
                          color: _navy,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Main content ─────────────────────────────────────────────
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 44,
                  vertical: 36,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [

                    // ── HEADER ────────────────────────────────────────────
                    _buildHeader(font, typeAr, typeEn, accent, qrPayload),
                    pw.SizedBox(height: 18),
                    _hairline(accent),
                    pw.SizedBox(height: 18),

                    // ── TRIPARTITE FLOW (conditional) ─────────────────────
                    if (report.isTripartite) ...[
                      _buildTripartiteFlow(font, report, accent),
                      pw.SizedBox(height: 18),
                      _hairline(accent),
                      pw.SizedBox(height: 18),
                    ],

                    // ── AMOUNT DISPLAY ────────────────────────────────────
                    _buildAmountBlock(
                      font,
                      amountStr,
                      report.currencyNameAr,
                      tafqeetStr,
                      accent,
                      accentBg,
                    ),
                    pw.SizedBox(height: 20),
                    _hairline(_border),
                    pw.SizedBox(height: 14),

                    // ── METADATA GRID ─────────────────────────────────────
                    _buildMetadataGrid(font, report, stateAr, dateStr),
                    pw.SizedBox(height: 20),

                    // ── SECURITY FOOTER ───────────────────────────────────
                    _buildSecurityFooter(font, report, accent),
                  ],
                ),
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

  // ── Header ────────────────────────────────────────────────────────────────

  pw.Widget _buildHeader(
    pw.Font font,
    String typeAr,
    String typeEn,
    PdfColor accent,
    String qrPayload,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Logo badge (right in RTL → visually left)
        pw.Container(
          width: 72,
          height: 72,
          decoration: pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: _gold, width: 1.5),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'قيد',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 22,
                  color: _gold,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Qayd',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ),

        // Centre: type badge
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                typeAr,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 17,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              typeEn,
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                color: _muted,
              ),
            ),
          ],
        ),

        // QR code (top-right, left in RTL → visually right)
        pw.BarcodeWidget(
          barcode: Barcode.qrCode(),
          data: qrPayload,
          width: 72,
          height: 72,
          drawText: false,
        ),
      ],
    );
  }

  // ── Tripartite flow map ───────────────────────────────────────────────────

  pw.Widget _buildTripartiteFlow(
    pw.Font font,
    VoucherReportDto report,
    PdfColor accent,
  ) {
    // Derive party names based on role
    final isReceiptLeg = report.tripartiteRole == 'receipt';

    final partyA = isReceiptLeg
        ? report.counterpartyName   // original sender
        : (report.linkedPartyName ?? '—');

    final partyC = report.affectedName; // intermediary (Qayd user)

    final partyB = isReceiptLeg
        ? (report.linkedPartyName ?? '—')
        : report.counterpartyName;  // final recipient

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(
            'مسار التحويل الثلاثي',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: _muted,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            _flowPartyBox(font, 'المُرسِل\n(الأصلي)', partyA, accent),
            _flowArrow(font, accent),
            _flowPartyBox(font, 'الوسيط\n(مستخدم قيد)', partyC, accent,
                isCenter: true),
            _flowArrow(font, accent),
            _flowPartyBox(
                font, 'المستفيد\n(النهائي)', partyB, accent),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _goldLight,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _gold, width: 0.5),
          ),
          child: pw.Text(
            'هذا السند يُمثّل ${isReceiptLeg ? "دور الاستلام" : "دور الدفع"} في تحويل ثلاثي الأطراف — '
            'يرتبط السندان ببعضهما تشفيريًا لضمان الشفافية الكاملة.',
            style: pw.TextStyle(font: font, fontSize: 8, color: _muted),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  pw.Widget _flowPartyBox(
    pw.Font font,
    String roleLabel,
    String name,
    PdfColor accent, {
    bool isCenter = false,
  }) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: pw.BoxDecoration(
        color: isCenter ? _navy : _light,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: isCenter ? accent : _border,
          width: isCenter ? 1.5 : 1,
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            roleLabel,
            style: pw.TextStyle(
              font: font,
              fontSize: 7.5,
              color: isCenter ? accent : _muted,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            name,
            style: pw.TextStyle(
              font: font,
              fontSize: 9.5,
              color: isCenter ? PdfColors.white : _navy,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _flowArrow(pw.Font font, PdfColor accent) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(width: 20, height: 1.5, color: accent),
          pw.Container(
            width: 6,
            height: 6,
            decoration: pw.BoxDecoration(
              color: accent,
              shape: pw.BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ── Amount block ─────────────────────────────────────────────────────────

  pw.Widget _buildAmountBlock(
    pw.Font font,
    String amountStr,
    String currencyNameAr,
    String tafqeet,
    PdfColor accent,
    PdfColor accentBg,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: pw.BoxDecoration(
            color: accentBg,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: accent, width: 1.2),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'المبلغ',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: _muted,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                amountStr,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 36,
                  color: _navy,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                currencyNameAr,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 13,
                  color: accent,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Tafqeet (amount in Arabic words)
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: pw.BoxDecoration(
            color: _light,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _border, width: 1),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  tafqeet,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10.5,
                    color: _navy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Metadata grid ─────────────────────────────────────────────────────────

  pw.Widget _buildMetadataGrid(
    pw.Font font,
    VoucherReportDto report,
    String stateAr,
    String dateStr,
  ) {
    final rows = <MapEntry<String, String>>[
      MapEntry('رقم السند', _shortId(report.voucherId)),
      MapEntry('التاريخ', dateStr),
      MapEntry('الحالة', stateAr),
      MapEntry('الحساب المتأثر', report.affectedName),
      MapEntry('الطرف المقابل', report.counterpartyName),
      if (_notEmpty(report.referenceNumber))
        MapEntry('المرجع', report.referenceNumber!.trim()),
      if (_notEmpty(report.description))
        MapEntry('البيان', report.description!.trim()),
      if (_notEmpty(report.notes))
        MapEntry('ملاحظات', report.notes!.trim()),
    ];

    final widgets = <pw.Widget>[];
    for (var i = 0; i < rows.length; i++) {
      widgets.add(_metaRow(font, rows[i].key, rows[i].value, isEven: i.isEven));
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  pw.Widget _metaRow(
    pw.Font font,
    String label,
    String value, {
    bool isEven = true,
  }) {
    return pw.Container(
      color: isEven ? PdfColors.white : _light,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: _muted,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Container(width: 1, height: 14, color: _border,
            margin: const pw.EdgeInsets.symmetric(horizontal: 10)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 10.5,
                color: _navy,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── Security footer ───────────────────────────────────────────────────────

  pw.Widget _buildSecurityFooter(
    pw.Font font,
    VoucherReportDto report,
    PdfColor accent,
  ) {
    final hasSig = report.signatureHex != null &&
        report.signatureHex!.isNotEmpty;
    final hasPubKey = report.signerPublicKeyHex != null &&
        report.signerPublicKeyHex!.isNotEmpty;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _light,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Seal line
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                '— وثيقة موقَّعة تشفيريًا عبر قيد —',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: accent,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: _border, thickness: 0.5),
          pw.SizedBox(height: 8),

          // Signature hex
          if (hasSig) ...[
            _sigRow(font, 'توقيع Ed25519', _truncateHex(report.signatureHex!)),
            pw.SizedBox(height: 5),
          ],

          // Public key
          if (hasPubKey) ...[
            _sigRow(font, 'المفتاح العام', _truncateHex(report.signerPublicKeyHex!)),
            pw.SizedBox(height: 5),
          ],

          if (!hasSig && !hasPubKey)
            pw.Center(
              child: pw.Text(
                'سند مسودة — التوقيع الرقمي يُضاف عند التأكيد',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8.5,
                  color: _muted,
                ),
              ),
            ),

          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'هذا السند صادر من تطبيق قيد للمحاسبة الشخصية — سجل دائم وغير قابل للتعديل',
              style: pw.TextStyle(font: font, fontSize: 7.5, color: _muted),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sigRow(pw.Font font, String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 7.5, color: _muted),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 7.5, color: _navy),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  pw.Widget _hairline(PdfColor color) =>
      pw.Divider(color: color, thickness: 0.75);

  bool _notEmpty(String? s) => s != null && s.trim().isNotEmpty;

  String _shortId(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 8)}…${id.substring(id.length - 8)}';
  }

  String _truncateHex(String hex) {
    if (hex.length <= 32) return hex;
    return '${hex.substring(0, 16)}…${hex.substring(hex.length - 16)}';
  }

  String _stateAr(String code) {
    return switch (code) {
      'draft'     => 'مسودة',
      'confirmed' => 'مؤكد',
      'settled'   => 'مسوّى',
      _           => code,
    };
  }

  // ── Tafqeet ───────────────────────────────────────────────────────────────
  // Converts an amount in minor units to Arabic words (تفقيط).

  String _tafqeet(int minorUnits, int digits, String currencyNameAr) {
    final divisor = math.pow(10, digits).toInt();
    final major = minorUnits ~/ divisor;
    final minor = minorUnits % divisor;

    final majorWords = _intToArabic(major);
    if (minor == 0) {
      return 'فقط $majorWords $currencyNameAr لا غير';
    }
    final minorWords = _intToArabic(minor);
    return 'فقط $majorWords $currencyNameAr و$minorWords لا غير';
  }

  static const _ones = [
    '', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة',
    'ستة', 'سبعة', 'ثمانية', 'تسعة', 'عشرة',
    'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر', 'خمسة عشر',
    'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر',
  ];

  static const _tens = [
    '', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون',
    'ستون', 'سبعون', 'ثمانون', 'تسعون',
  ];

  String _intToArabic(int n) {
    if (n == 0) return 'صفر';
    if (n < 0) return 'سالب ${_intToArabic(-n)}';

    final parts = <String>[];
    var rem = n;

    if (rem >= 1000000) {
      final m = rem ~/ 1000000;
      rem = rem % 1000000;
      if (m == 1)       parts.add('مليون');
      else if (m == 2)  parts.add('مليونان');
      else if (m <= 10) parts.add('${_intToArabic(m)} ملايين');
      else              parts.add('${_intToArabic(m)} مليون');
    }

    if (rem >= 1000) {
      final t = rem ~/ 1000;
      rem = rem % 1000;
      if (t == 1)       parts.add('ألف');
      else if (t == 2)  parts.add('ألفان');
      else if (t <= 10) parts.add('${_ones[t]} آلاف');
      else              parts.add('${_intToArabic(t)} ألف');
    }

    if (rem >= 100) {
      final h = rem ~/ 100;
      rem = rem % 100;
      if (h == 1)      parts.add('مئة');
      else if (h == 2) parts.add('مئتان');
      else             parts.add('${_ones[h]} مئة');
    }

    if (rem > 0) {
      if (rem < 20) {
        parts.add(_ones[rem]);
      } else {
        final t = rem ~/ 10;
        final o = rem % 10;
        parts.add(o == 0 ? _tens[t] : '${_ones[o]} و${_tens[t]}');
      }
    }

    return parts.join(' و');
  }
}
