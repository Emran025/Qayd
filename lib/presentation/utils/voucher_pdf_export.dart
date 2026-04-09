import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/data/dtos/voucher_report_dto.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/utils/share_pdf_bytes.dart';
import 'package:qayd/presentation/utils/voucher_share_text_resolver.dart';
import 'package:qayd/presentation/pages/vouchers/widgets/voucher_share_review_sheet.dart';

Future<void> shareVoucherAsPdf(
  BuildContext context,
  GetVoucherDetailsOutput data,
) async {
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
    ),
  );

  final dto = VoucherReportDto(
    voucherId: data.id,
    typeCode: data.typeCode,
    stateCode: data.stateCode,
    dateIso: data.dateIso,
    amountMinorUnits: data.amountMinorUnits,
    currencyCode: data.currencyCode,
    currencyNameAr: data.currencyNameAr,
    currencySymbol: data.currencySymbol,
    currencyDigits: data.currencyDigits,
    counterpartyAccountId: data.counterpartyAccountId,
    counterpartyName: data.counterpartyName,
    affectedAccountId: data.affectedAccountId,
    affectedName: data.affectedName,
    referenceNumber: data.referenceNumber,
    description: data.description,
    notes: data.notes,
    qrData: data.qrData,
    createdAtIso: data.createdAtIso,
    confirmedAtIso: data.confirmedAtIso,
    settledAtIso: data.settledAtIso,
    isTripartite: data.isTripartite,
    tripartiteRole: data.tripartiteRole,
    linkedPartyName: data.linkedPartyName,
    senderSignatureHex: data.senderSignatureHex,
    receiverSignatureHex: data.receiverSignatureHex,
    senderPublicKeyHex: data.senderPublicKeyHex,
    receiverPublicKeyHex: data.receiverPublicKeyHex,
    senderStatusCode: data.senderStatusCode,
    receiverStatusCode: data.receiverStatusCode,
  );

  Result<Uint8List> result;
  try {
    result = await InjectionContainer.voucherPdfGenerator.buildVoucherPdf(
      dto,
    );
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
    }
  }

  if (result.isFailure) {
    messenger.showSnackBar(
      SnackBar(content: Text(result.failureOrNull!.messageAr)),
    );
    return;
  }
  final bytes = result.valueOrNull!;
  try {
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
      final voucherType =
          data.typeCode == 'receipt' ? 'إشعار قبض' : 'إشعار صرف';
      shareText = 'مرفق لكم $voucherType من حساب ${data.affectedName}.\n'
          'المبلغ: $amountTextFormatter\n'
          'الطرف الآخر: ${data.counterpartyName}\n'
          'المرجع: ${data.referenceNumber ?? data.id.substring(0, 8)}\n'
          '\nمُصدّر آلياً وموثق رقمياً عبر نظام قيد المالي.';
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

    await sharePdfBytes(bytes, 'qayd_voucher_${data.id}.pdf', text: shareText);
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(AppStringsAr.exportPdfShareError)),
    );
  }
}
