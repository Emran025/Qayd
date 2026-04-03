import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareVoucherAsText(GetVoucherDetailsOutput data) async {
  final isReceipt = data.typeCode == 'receipt';
  final type = isReceipt
      ? AppStringsAr.voucherTypeReceipt
      : AppStringsAr.voucherTypePayment;
  final date = DateFormat.yMMMd('ar').format(DateTime.parse(data.dateIso));
  final amount = MoneyFormatter.formatWithSymbol(
    data.amountMinorUnits / (data.currencyDigits == 0 ? 1 : 100),
    data.currencySymbol,
    fractionalDigits: data.currencyDigits,
  );

  final buffer = StringBuffer();
  buffer.writeln('إشعار $type');
  buffer.writeln('التاريخ: $date');
  buffer.writeln('المبلغ: $amount');
  buffer.writeln('الحساب: ${data.affectedName}');
  buffer.writeln('الطرف الآخر: ${data.counterpartyName}');
  if (data.description != null && data.description!.isNotEmpty) {
    buffer.writeln('البيان: ${data.description}');
  }

  await Share.share(buffer.toString());
}

Future<void> shareVoucherAsImage(BuildContext context, GlobalKey boundaryKey) async {
  try {
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final pngBytes = byteData.buffer.asUint8List();
    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/voucher_receipt.png';
    final file = File(imagePath);
    await file.writeAsBytes(pngBytes);

    await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], text: 'إيصال القيد');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تعذر مشاركة الإيصال كصورة: $e')),
    );
  }
}
