import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path_provider/path_provider.dart';
import 'package:qayd/presentation/pages/vouchers/widgets/voucher_share_review_sheet.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/presentation/utils/numerical_styling.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/utils/voucher_share_text_resolver.dart';
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
  GetVoucherDetailsOutput data, {
  bool forceNormalLayout = false,
  bool forceTripartiteLayout = false,
}) async {
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
          child: VoucherImageCard(
            data: data,
            forceNormalLayout: forceNormalLayout,
            forceTripartiteLayout: forceTripartiteLayout,
          ),
        ),
      ),
    ),
  );

  try {
    Overlay.of(context).insert(overlay);

    // Wait for layout + paint (increased slightly for safety with complex UI)
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final boundary = boundaryKey.currentContext?.findRenderObject()
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

    var shareText = await resolveVoucherShareText(data);

    // Fallback if no template is found
    if (shareText == null || shareText.isEmpty) {
      final amountTextFormatter = MoneyFormatter.formatWithSymbol(
        data.amountMinorUnits /
            (data.currencyDigits == 0
                ? 1
                : (data.currencyDigits == 2 ? 100 : 100)),
        data.currencySymbol,
        fractionalDigits: data.currencyDigits,
      );

      if (data.isTripartite) {
        final isReceiptLeg = data.tripartiteRole == 'receipt' ||
            data.tripartiteRole == 'intermediary_receipt';
        final sender = isReceiptLeg
            ? data.counterpartyName
            : (data.linkedPartyName ?? 'المرسل');
        final receiver = isReceiptLeg
            ? (data.linkedPartyName ?? 'المستلم')
            : data.counterpartyName;

        final shortId = data.id.length > 8 ? data.id.substring(0, 8) : data.id;
        shareText =
            'مرفق لكم إشعار تحويل مالي من حساب $sender إلى حساب $receiver.\n'
            'المبلغ: $amountTextFormatter\n'
            'المرجع: ${data.referenceNumber ?? shortId}\n'
            '\nمُصدّر آلياً وموثق رقمياً عبر نظام قيد المالي.';
      } else {
        final voucherType =
            data.typeCode == 'receipt' ? 'إشعار قبض' : 'إشعار صرف';
        final shortId = data.id.length > 8 ? data.id.substring(0, 8) : data.id;
        shareText = 'مرفق لكم $voucherType من حساب ${data.affectedName}.\n'
            'المبلغ: $amountTextFormatter\n'
            'الطرف الآخر: ${data.counterpartyName}\n'
            'المرجع: ${data.referenceNumber ?? shortId}\n'
            '\nمُصدّر آلياً وموثق رقمياً عبر نظام قيد المالي.';
      }
      if (data.senderSignatureHex != null ||
          data.receiverSignatureHex != null) {
        shareText +=
            '\nبصمة التحقق: ${data.senderSignatureHex ?? data.receiverSignatureHex}';
      }
    }

    // Preview and edit Step
    final editedText = await VoucherSharePreviewSheet.show(context, shareText);
    if (editedText == null) return; // Cancelled
    shareText = editedText;

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: shareText,
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
  const VoucherImageCard({
    super.key,
    required this.data,
    this.forceNormalLayout = false,
    this.forceTripartiteLayout = false,
  });

  final GetVoucherDetailsOutput data;
  final bool forceNormalLayout;
  final bool forceTripartiteLayout;

  bool get _isTripartite => forceTripartiteLayout
      ? true
      : forceNormalLayout
          ? false
          : data.isTripartite;

  String? get _tripartiteRole => forceTripartiteLayout
      ? 'receipt'
      : forceNormalLayout
          ? null
          : data.tripartiteRole;

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

    final dateFmt = intl.DateFormat('dd/MM/yyyy', 'en');
    final dateStr = dateFmt.format(DateTime.parse(data.dateIso));
    final createdFmt = intl.DateFormat('hh:mm:ss a  dd/MM/yyyy', 'en');
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
                      if (_isTripartite)
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
    final prefs = InjectionContainer.sharedPreferences;
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
                _text(
                    prefs.getString('pdf_header_title') ??
                        'قيد — المحاسبة الشخصية',
                    12,
                    _navy,
                    bold: true),
                const SizedBox(height: 2),
                _text(
                    prefs.getString('pdf_header_subtitle') ??
                        'نظام السندات المالية المشفّرة',
                    8,
                    _muted),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Logo
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // English info
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Qayd — Personal Accounting',
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.bold, color: _navy),
                ),
                SizedBox(height: 2),
                Text(
                  'Encrypted Financial Voucher System',
                  style: TextStyle(fontSize: 7, color: _muted),
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
    final prefs = InjectionContainer.sharedPreferences;
    final labelNo = prefs.getString('pdf_label_voucher_no') ?? 'رقم السند:';
    final labelDate = prefs.getString('pdf_label_date') ?? 'التاريخ:';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _borderedBox(labelNo, _shortId(data.id)),
              _borderedBox(labelDate, dateStr),
            ],
          ),
          const SizedBox(height: 8),
          _text(titleAr, 13, _navy, bold: true, align: TextAlign.center),
          if (_isTripartite) ...[
            const SizedBox(height: 1),
            _text(
              prefs.getString('pdf_mediator_name') ??
                  prefs.getString('company_name') ??
                  'نظام قيد المالي',
              8.5,
              _muted,
              align: TextAlign.center,
            ),
          ],
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

    if (_isTripartite) {
      final isReceiptLeg = _tripartiteRole == 'receipt' ||
          _tripartiteRole == 'intermediary_receipt';

      final senderName = isReceiptLeg
          ? data.counterpartyName
          : (data.linkedPartyName ?? data.counterpartyName);
      final receiverName = isReceiptLeg
          ? (data.linkedPartyName ?? '—')
          : data.counterpartyName;

      if (isDebit) {
        sectionLabel = 'بيانات القيد (المدين) — من حساب المُرسِل:';
        accountName = senderName;
        descText = data.description?.isNotEmpty == true
            ? data.description
            : (data.isContingent
                ? 'إشعار سند تحويل ثلاثي — من المُرسِل ($senderName) إلى المُستلِم ($receiverName).'
                : 'تحويل مالي مزدوج عبر الصندوق — خصم من حساب $senderName وإضافة إلى حساب $receiverName.');
        notesText = 'يُعتبر هذا الإشعار توثيقاً رسمياً بالخصم من حساب المُرسِل.';
      } else {
        sectionLabel = 'بيانات القيد (الدائن) — إلى حساب المُستلِم:';
        accountName = receiverName;
        descText = data.isContingent
            ? 'إشعار سند تحويل ثلاثي — من المُرسِل ($senderName) إلى المُستلِم ($receiverName).'
            : 'تمت إضافة المبلغ إلى حساب $receiverName من حساب $senderName عبر الصندوق كتحويل مزدوج.';
        notesText =
            'يُعتبر هذا الإشعار توثيقاً رسمياً بالإضافة إلى حساب المُستلِم.';
      }
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
                    Row(
                      children: [
                        _text(
                            InjectionContainer.sharedPreferences
                                    .getString('pdf_label_from') ??
                                sectionLabel,
                            10,
                            _navy,
                            bold: true),
                        const SizedBox(width: 5),
                        _text(accountName, 10, accent, bold: true),
                      ],
                    ),
                    if (_notEmpty(descText)) ...[
                      const SizedBox(height: 5),
                      _labeledLine(
                          InjectionContainer.sharedPreferences
                                  .getString('pdf_label_description') ??
                              'البيان التفصيلي:',
                          descText!),
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
    final hasSenderSig =
        data.senderSignatureHex != null && data.senderSignatureHex!.isNotEmpty;
    final hasReceiverSig = data.receiverSignatureHex != null &&
        data.receiverSignatureHex!.isNotEmpty;

    if (_isTripartite) {
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
            data.typeCode == 'receipt'
                ? '(توقيع العميل المرسل)'
                : '(توقيع العميل المستلم)',
            data.typeCode == 'receipt' ? hasSenderSig : hasReceiverSig,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 70,
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
      height: 70,
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
                _text(
                    InjectionContainer.sharedPreferences
                            .getString('pdf_footer_text') ??
                        'المصدر: تطبيق قيد للمحاسبة الشخصية',
                    7.5,
                    _muted),
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
    final style = GoogleFonts.cairo(
      fontSize: size,
      color: color,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      height: 1.35,
    );

    // Apply numerical scaling for visual harmony with Cairo font
    return Text.rich(
      buildNumericalScaledSpan(text, style),
      textDirection: dir,
      textAlign: align,
    );
  }

  static bool _notEmpty(String? s) => s != null && s.trim().isNotEmpty;

  String _buildTitle(GetVoucherDetailsOutput d, String typeAr) {
    if (!_isTripartite) return typeAr;
    return 'سند تحويل ثلاثي — إشعار للطرفين';
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
