import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qayd/application/vouchers/dtos/get_tripartite_detail_output.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/core/utils/currency_util.dart';

import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/utils/voucher_share_text_resolver.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;
import 'package:qayd/presentation/pages/vouchers/widgets/voucher_share_review_sheet.dart';
import 'package:qayd/presentation/utils/whatsapp_flavor_picker.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_input.dart';
import 'package:qayd/data/messaging/messaging_intent_launcher.dart';
import 'package:qayd/core/result/result.dart';

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

    // Include net balance in fallback if available
    final balanceParts = data.counterpartyBalances.entries.map((e) {
      final digits = (e.key == data.currencyCode) ? data.currencyDigits : 2;
      final divisor = (digits == 0 ? 1 : (digits == 2 ? 100 : 1000)).toDouble();
      final value = e.value / divisor;
      final absValue = value.abs();
      final label = data.counterpartyNature == 'debit'
          ? value > 0
              ? AppStringsAr.onYou
              : AppStringsAr.your
          : value < 0
              ? AppStringsAr.onYou
              : AppStringsAr.your;
      return '${MoneyFormatter.formatDecimal(absValue, minimumFractionDigits: digits, maximumFractionDigits: digits)} ${CurrencyUtil.getArabicName(e.key)} $label'
          .trim();
    }).toList();
    if (balanceParts.isNotEmpty) {
      buffer.writeln('الرصيد الإجمالي: ${balanceParts.join(", ")}');
    }

    buffer.writeln('العميل: ${data.counterpartyName}');
    buffer.writeln('الحساب: ${data.affectedName}');
    if (data.description != null && data.description!.isNotEmpty) {
      buffer.writeln('البيان: ${data.description}');
    }
    buffer.writeln('\n--');
    buffer.writeln(AppStringsAr.automaticallyExportedAndDigitally);
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

  final method = await ShareMethodPicker.show(context);
  if (method == null) return;

  if (method == ShareMethod.system) {
    await SharePlus.instance.share(ShareParams(text: shareText));
  } else {
    final flavor = method == ShareMethod.whatsappStandard
        ? WhatsAppFlavor.standard
        : WhatsAppFlavor.business;

    String? phoneNumber;
    if (data.counterpartyAccountId.isNotEmpty) {
      final aR = await InjectionContainer.getAccountDetailsUseCase(
        GetAccountDetailsInput(accountId: data.counterpartyAccountId),
      );
      if (aR.isSuccess) {
        final account = aR.valueOrNull!;
        phoneNumber = account.whatsappNumber ?? account.phoneNumber;
      }
    }

    await MessagingIntentLauncher.shareToWhatsApp(
      flavor: flavor,
      message: shareText,
      phoneNumber: phoneNumber,
    );
  }
}

Future<void> shareTripartiteAsText(
    BuildContext context, GetTripartiteDetailOutput data) async {
  final dateFmt = DateFormat('dd/MM/yyyy', 'en');
  final date = dateFmt.format(DateTime.parse(data.dateIso));
  final amount = MoneyFormatter.formatWithSymbol(
    data.amountMinorUnits / (data.currencyDigits == 0 ? 1 : 100),
    CurrencyUtil.getArabicName(data.currencyCode),
    fractionalDigits: data.currencyDigits,
  );

  var shareText = await resolveTripartiteShareText(data);

  // Fallback if no template is found
  if (shareText == null || shareText.isEmpty) {
    final buffer = StringBuffer();
    buffer.writeln(AppStringsAr.brokerTransferNotice);
    buffer.writeln('التاريخ: $date');
    buffer.writeln('المبلغ: $amount');
    buffer.writeln('المرسل: ${data.sourceName}');
    buffer.writeln('المستلم: ${data.destinationName}');
    buffer.writeln('الوسيط: ${data.mediatorName}');
    if (data.description != null && data.description!.isNotEmpty) {
      buffer.writeln('البيان: ${data.description}');
    }
    buffer.writeln('\n--');
    buffer.writeln(AppStringsAr.automaticallyExportedAndDigitally);
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

  await SharePlus.instance.share(ShareParams(text: shareText));
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

    final method = await ShareMethodPicker.show(context);
    if (method == null) return;

    if (method == ShareMethod.system) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: shareText,
        ),
      );
    } else {
      final flavor = method == ShareMethod.whatsappStandard
          ? WhatsAppFlavor.standard
          : WhatsAppFlavor.business;

      String? phoneNumber;
      if (data.counterpartyAccountId.isNotEmpty) {
        final aR = await InjectionContainer.getAccountDetailsUseCase(
          GetAccountDetailsInput(accountId: data.counterpartyAccountId),
        );
        if (aR.isSuccess) {
          final account = aR.valueOrNull!;
          phoneNumber = account.whatsappNumber ?? account.phoneNumber;
        }
      }

      await MessagingIntentLauncher.shareToWhatsApp(
        flavor: flavor,
        message: shareText,
        fileAbsolutePath: file.path,
        phoneNumber: phoneNumber,
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تعذر مشاركة الإيصال كصورة: $e')),
    );
  }
}
