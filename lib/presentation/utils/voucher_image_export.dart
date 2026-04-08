import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:share_plus/share_plus.dart';

/// Shows a professional voucher overlay, captures it as a high-res PNG,
/// then shares via [share_plus].
///
/// This is the production image export — it matches the reference design:
/// - Header bar with bilingual "قيد / Qayd" branding + logo
/// - Voucher number + date in bordered boxes
/// - Entry sections with amount box + details
/// - Signature row (no manager signature)
/// - QR code + footer

Future<void> shareVoucherAsFormattedImage(
  BuildContext context,
  GetVoucherDetailsOutput data,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final boundaryKey = GlobalKey();

  // 1. Show a loading indicator so the user knows processing is happening.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(color: Color(0xFFC9A227)), // Gold accent
    ),
  );

  // 2. Show the voucher card in a hidden overlay for capture.
  final overlay = OverlayEntry(
    builder: (_) => Positioned(
      left: -9999, // off-screen
      top: -9999,
      child: RepaintBoundary(
        key: boundaryKey,
        child: Material(
          color: Colors.transparent,
          child: VoucherImageCard(data: data),
        ),
      ),
    ),
  );

  try {
    Overlay.of(context).insert(overlay);

    // Wait for layout + paint (increased slightly for safety with complex UI)
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception('تعذر الوصول إلى كائن الرسم');
    }

    // 3. Pixel ratio 2.5 is high-res (1375px) but much faster than 3.0 (1650px)
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    // Clean up capture overlay and loading dialog as soon as data is captured
    overlay.remove();
    if (context.mounted) Navigator.of(context).pop();

    if (byteData == null) {
      throw Exception('تعذر استخراج بيانات الصورة');
    }

    final pngBytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final fileName =
        'qayd_voucher_${data.id.substring(0, math.min(8, data.id.length))}.png';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pngBytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: 'إيصال قيد — ${data.typeCode == 'receipt' ? 'سند قبض' : 'سند صرف'}',
    );
  } catch (e) {
    // Ensure cleanup on failure
    if (overlay.mounted) overlay.remove();
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text('تعذر مشاركة الإيصال: $e'),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Voucher Image Card ───────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

/// A self-contained, theme-independent image card matching the
/// Galal Nasser Exchange reference design.
class VoucherImageCard extends StatelessWidget {
  const VoucherImageCard({super.key, required this.data});

  final GetVoucherDetailsOutput data;

  // ── Palette (self-contained, no theme dependency) ──
  static const _navy = Color(0xFF0F2741);
  static const _gold = Color(0xFFC9A227);
  static const _emerald = Color(0xFF047857);
  static const _muted = Color(0xFF64748B);
  static const _headerBg = Color(0xFFE8EDF3);
  static const _border = Color(0xFFCBD5E1);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _errorRed = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final isReceipt = data.typeCode == 'receipt';
    final accent = isReceipt ? _emerald : _gold;
    final typeAr = isReceipt ? 'سند قبض' : 'سند صرف';

    final dateFmt = intl.DateFormat('dd/MM/yyyy');
    final dateStr = dateFmt.format(DateTime.parse(data.dateIso));
    final createdFmt = intl.DateFormat('hh:mm:ss a  dd/MM/yyyy');
    final createdStr = createdFmt.format(DateTime.parse(data.createdAtIso));

    final divisor = math.pow(10, data.currencyDigits).toDouble();
    final amount = data.amountMinorUnits / divisor;
    final fmt = intl.NumberFormat('#,##0.${'0' * data.currencyDigits}', 'en');
    final amountStr = '#${fmt.format(amount)} ${data.currencyCode}#';

    final qrPayload = data.qrData ?? data.id;
    final titleAr = _buildTitle(data, typeAr);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 550,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Watermark logo in the center
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _headerBar(),
                _titleRow(titleAr, dateStr),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _entrySection(
                        sectionType: 'debit',
                        amountStr: amountStr,
                        accent: accent,
                      ),
                      const SizedBox(height: 8),
                      if (data.isTripartite)
                        _entrySection(
                          sectionType: 'credit',
                          amountStr: amountStr,
                          accent: accent,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _signatureRow(),
                ),
                const SizedBox(height: 10),
                _footer(createdStr, qrPayload),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HEADER
  // ════════════════════════════════════════════════════════════════════════════

  Widget _headerBar() {
    return Container(
      color: _headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Arabic info (right in RTL)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text('قيد — المحاسبة الشخصية', 12, _navy, bold: true),
                const SizedBox(height: 2),
                _text('نظام السندات المالية المشفّرة', 8, _muted),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Logo
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // English info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _text(
                  'Qayd — Personal Accounting',
                  9,
                  _navy,
                  bold: true,
                  dir: TextDirection.ltr,
                ),
                const SizedBox(height: 2),
                _text(
                  'Encrypted Financial Voucher System',
                  7,
                  _muted,
                  dir: TextDirection.ltr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TITLE ROW
  // ════════════════════════════════════════════════════════════════════════════

  Widget _titleRow(String titleAr, String dateStr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _borderedBox('رقم السند:', _shortId(data.id)),
              _borderedBox('التاريخ:', dateStr),
            ],
          ),
          const SizedBox(height: 8),
          _text(titleAr, 13, _navy, bold: true, align: TextAlign.center),
        ],
      ),
    );
  }

  Widget _borderedBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: _navy),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _text(label, 9, _navy, bold: true),
          const SizedBox(width: 4),
          _text(value, 10, _navy, dir: TextDirection.ltr),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ENTRY SECTION
  // ════════════════════════════════════════════════════════════════════════════

  Widget _entrySection({
    required String sectionType,
    required String amountStr,
    required Color accent,
  }) {
    final isDebit = sectionType == 'debit';
    final isReceipt = data.typeCode == 'receipt';

    String sectionLabel;
    String accountName;
    String? descText;
    String? notesText;

    if (data.isTripartite) {
      final isReceiptLeg =
          data.tripartiteRole == 'receipt' ||
          data.tripartiteRole == 'intermediary_receipt';

      if (isDebit) {
        sectionLabel = isReceiptLeg
            ? 'بيانات القيد (المدين) - من حساب العميل:'
            : 'بيانات القيد (المدين) - من حساب الوسيط:';
        accountName = isReceiptLeg ? data.counterpartyName : data.affectedName;
      } else {
        sectionLabel = isReceiptLeg
            ? 'بيانات القيد (الدائن) - إلى حساب الوسيط:'
            : 'بيانات القيد (الدائن) - إلى حساب العميل المستلم:';
        accountName = isReceiptLeg ? data.affectedName : data.counterpartyName;
      }

      descText = data.description;
      notesText = isDebit
          ? 'يعتبر هذا السند إشعاراً بالخصم من رصيد حسابكم الجاري.'
          : 'يعتبر هذا السند إشعاراً بالإضافة إلى رصيد حسابكم الجاري كتحويل مالي مستلم.';
    } else {
      sectionLabel = isReceipt
          ? 'بيانات القيد - من حساب العميل:'
          : 'بيانات القيد - إلى حساب العميل:';
      accountName = data.counterpartyName;
      descText = data.description;
      notesText = data.notes;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Details (right side in RTL)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RichText(
                      textDirection: TextDirection.rtl,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$sectionLabel ',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: _navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: accountName,
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_notEmpty(descText)) ...[
                      const SizedBox(height: 5),
                      _labeledLine('البيان التفصيلي:', descText!),
                    ],
                    if (_notEmpty(notesText)) ...[
                      const SizedBox(height: 3),
                      _labeledLine('الملاحظات:', notesText!),
                    ],
                    if (_notEmpty(data.referenceNumber)) ...[
                      const SizedBox(height: 3),
                      _labeledLine('المرجع:', data.referenceNumber!),
                    ],
                  ],
                ),
              ),
            ),

            // Amount box (left side in RTL)
            Container(
              width: 90,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: _border)),
              ),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _navy, width: 1.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _text(
                    amountStr,
                    8,
                    _navy,
                    bold: true,
                    dir: TextDirection.ltr,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labeledLine(String label, String value) {
    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: GoogleFonts.cairo(
              fontSize: 9,
              color: _navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: GoogleFonts.cairo(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SIGNATURE ROW
  // ════════════════════════════════════════════════════════════════════════════

  Widget _signatureRow() {
    final hasSenderSig = data.senderSignatureHex != null && data.senderSignatureHex!.isNotEmpty;
    final hasReceiverSig = data.receiverSignatureHex != null && data.receiverSignatureHex!.isNotEmpty;

    if (data.isTripartite) {
      return Row(
        children: [
          Expanded(child: _sigBox('(توقيع العميل الأول)', hasSenderSig)),
          const SizedBox(width: 8),
          Expanded(child: _sigBox('(توقيع العميل الثاني)', hasReceiverSig)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2, 
          child: _sigBox(
            data.typeCode == 'receipt' ? '(توقيع العميل المرسل)' : '(توقيع العميل المستلم)', 
            data.typeCode == 'receipt' ? hasSenderSig : hasReceiverSig,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: _border, width: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _text('حالة التوقيع', 7, _muted),
                const SizedBox(height: 3),
                _text(
                  _agreementLabel(data.receiverStatusCode),
                  8,
                  _agreementColor(data.receiverStatusCode),
                  bold: true,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sigBox(String label, bool hasSig) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: _border, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (hasSig)
            Expanded(
              child: Center(
                child: _text('✓ موقّع رقمياً', 9, _emerald, bold: true),
              ),
            ),
          Container(height: 0.5, color: _border),
          const SizedBox(height: 3),
          _text(label, 8, _muted, align: TextAlign.center),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FOOTER
  // ════════════════════════════════════════════════════════════════════════════

  Widget _footer(String createdStr, String qrPayload) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Info (right side in RTL)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text('تم الإنشاء:  $createdStr', 7.5, _muted),
                const SizedBox(height: 2),
                _text('المصدر: تطبيق قيد للمحاسبة الشخصية', 7.5, _muted),
                if (_notEmpty(data.senderPublicKeyHex)) ...[
                  const SizedBox(height: 2),
                  _text(
                    'مفتاح المرسل: ${_truncHex(data.senderPublicKeyHex!)}',
                    6.5,
                    _muted,
                    dir: TextDirection.ltr,
                  ),
                ],
                if (_notEmpty(data.receiverPublicKeyHex)) ...[
                  const SizedBox(height: 1),
                  _text(
                    'مفتاح المستلم: ${_truncHex(data.receiverPublicKeyHex!)}',
                    6.5,
                    _muted,
                    dir: TextDirection.ltr,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // QR
          Column(
            children: [
              QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 56,
                gapless: true,
              ),
              const SizedBox(height: 2),
              _text('تحقق من السند', 7, _muted),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  static Widget _text(
    String text,
    double size,
    Color color, {
    bool bold = false,
    TextAlign? align,
    TextDirection? dir,
  }) {
    return Text(
      text,
      textDirection: dir,
      textAlign: align,
      style: GoogleFonts.cairo(
        fontSize: size,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        height: 1.35,
      ),
    );
  }

  static bool _notEmpty(String? s) => s != null && s.trim().isNotEmpty;

  String _buildTitle(GetVoucherDetailsOutput d, String typeAr) {
    if (!d.isTripartite) return typeAr;
    final isReceiptLeg =
        d.tripartiteRole == 'receipt' ||
        d.tripartiteRole == 'intermediary_receipt';
    final legLabel = isReceiptLeg
        ? 'إشعار للطرفين'
        : 'إشعار قيد العميل المحوّل';
    return 'سند قيد مزدوج وإشعار قيد ($legLabel)';
  }

  static String _shortId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 6)}…${id.substring(id.length - 6)}';
  }

  static String _truncHex(String hex) {
    if (hex.length <= 24) return hex;
    return '${hex.substring(0, 12)}…${hex.substring(hex.length - 12)}';
  }

  static String _agreementLabel(String code) {
    return switch (code) {
      'underRequest' => 'بانتظار الموافقة',
      'accepted' => 'مقبول وموقّع',
      'rejected' => 'مرفوض',
      'unverified' => 'غير مؤكد',
      _ => code,
    };
  }

  static Color _agreementColor(String code) {
    return switch (code) {
      'accepted' => _emerald,
      'rejected' => _errorRed,
      'underRequest' => _gold,
      _ => _muted,
    };
  }
}
