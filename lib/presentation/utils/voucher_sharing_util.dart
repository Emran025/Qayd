import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qayd/application/vouchers/dtos/get_tripartite_detail_output.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/utils/voucher_share_text_resolver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qayd/presentation/pages/vouchers/widgets/voucher_share_review_sheet.dart';

Future<void> shareVoucherAsText(
    BuildContext context, GetVoucherDetailsOutput data) async {
  final isReceipt = data.typeCode == 'receipt';
  final type = isReceipt
      ? AppStringsAr.voucherTypeReceipt
      : AppStringsAr.voucherTypePayment;
  final dateFmt = DateFormat('dd/MM/yyyy', 'en');
  final date = dateFmt.format(DateTime.parse(data.dateIso));
  final amount = MoneyFormatter.formatWithSymbol(
    data.amountMinorUnits / (data.currencyDigits == 0 ? 1 : 100),
    data.currencySymbol,
    fractionalDigits: data.currencyDigits,
  );

  var shareText = await resolveVoucherShareText(data);

  // Fallback if no template is found
  if (shareText == null || shareText.isEmpty) {
    final buffer = StringBuffer();
    buffer.writeln('إشعار $type');
    buffer.writeln('التاريخ: $date');
    buffer.writeln('المبلغ: $amount');
    buffer.writeln('العميل: ${data.counterpartyName}');
    buffer.writeln('الحساب: ${data.affectedName}');
    if (data.description != null && data.description!.isNotEmpty) {
      buffer.writeln('البيان: ${data.description}');
    }
    buffer.writeln('\n--');
    buffer.writeln('مُصدّر آلياً وموثق رقمياً عبر نظام قيد');
    if (data.senderSignatureHex != null) {
      buffer.write('\n- توقيع المرسل: ${data.senderSignatureHex}');
    }
    if (data.receiverSignatureHex != null) {
      buffer.write('\n- توقيع المستلم: ${data.receiverSignatureHex}');
    }
    shareText = buffer.toString();
  }

  // Preview and edit Step
  final editedText = await VoucherSharePreviewSheet.show(context, shareText);
  if (editedText == null) return; // Cancelled
  shareText = editedText;

  await Share.share(shareText);
}

Future<void> shareTripartiteAsText(
    BuildContext context, GetTripartiteDetailOutput data) async {
  final dateFmt = DateFormat('dd/MM/yyyy', 'en');
  final date = dateFmt.format(DateTime.parse(data.dateIso));
  final amount = MoneyFormatter.formatWithSymbol(
    data.amountMinorUnits / (data.currencyDigits == 0 ? 1 : 100),
    data.currencySymbol,
    fractionalDigits: data.currencyDigits,
  );

  var shareText = await resolveTripartiteShareText(data);

  // Fallback if no template is found
  if (shareText == null || shareText.isEmpty) {
    final buffer = StringBuffer();
    buffer.writeln('إشعار تحويل وسيط');
    buffer.writeln('التاريخ: $date');
    buffer.writeln('المبلغ: $amount');
    buffer.writeln('المرسل: ${data.sourceName}');
    buffer.writeln('المستلم: ${data.destinationName}');
    buffer.writeln('الوسيط: ${data.mediatorName}');
    if (data.description != null && data.description!.isNotEmpty) {
      buffer.writeln('البيان: ${data.description}');
    }
    buffer.writeln('\n--');
    buffer.writeln('مُصدّر آلياً وموثق رقمياً عبر نظام قيد');
    if (data.senderSignatureHex != null) {
      buffer.write('\n- توقيع المرسل: ${data.senderSignatureHex}');
    }
    if (data.receiverSignatureHex != null) {
      buffer.write('\n- توقيع المستلم: ${data.receiverSignatureHex}');
    }
    shareText = buffer.toString();
  }

  // Preview and edit Step
  final editedText = await VoucherSharePreviewSheet.show(context, shareText);
  if (editedText == null) return; // Cancelled
  shareText = editedText;

  await Share.share(shareText);
}

Future<void> shareVoucherAsImage(BuildContext context, GlobalKey boundaryKey,
    GetVoucherDetailsOutput data) async {
  try {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final pngBytes = byteData.buffer.asUint8List();
    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/voucher_receipt.png';
    final file = File(imagePath);
    await file.writeAsBytes(pngBytes);

    var shareText = await resolveVoucherShareText(data);
    if (shareText == null || shareText.isEmpty) {
      shareText =
          'مرفق لكم إيصال قيد مالي رقم ${data.referenceNumber ?? data.id.substring(0, 8)}.\n\nموثق رقمياً عبر نظام قيد.';
    }

    // Preview and edit Step
    final editedText = await VoucherSharePreviewSheet.show(context, shareText);
    if (editedText == null) return; // Cancelled
    shareText = editedText;

    await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')],
        text: shareText);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تعذر مشاركة الإيصال كصورة: $e')),
    );
  }
}
