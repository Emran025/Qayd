import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/core/utils/currency_util.dart';
import 'package:qayd/data/dtos/voucher_report_dto.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;
import 'package:qayd/presentation/utils/voucher_share_text_resolver.dart';
import 'package:qayd/presentation/pages/vouchers/widgets/voucher_share_review_sheet.dart';
import 'package:qayd/presentation/utils/whatsapp_flavor_picker.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_input.dart';
import 'package:qayd/data/messaging/messaging_intent_launcher.dart';
import 'package:qayd/core/utils/text_sanitizer.dart';

Future<void> shareVoucherAsPdf(
  BuildContext context,
  GetVoucherDetailsOutput data, {
  bool forceNormalLayout = false,
  bool forceTripartiteLayout = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
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
    affectedName: TextSanitizer.sanitizeText(data.affectedName),
    referenceNumber: data.referenceNumber,
    description: TextSanitizer.sanitizeText(data.description ?? ""),
    notes: data.notes != null ? TextSanitizer.sanitizeText(data.notes!) : null,
    qrData: data.qrData,
    createdAtIso: data.createdAtIso,
    confirmedAtIso: data.confirmedAtIso,
    settledAtIso: data.settledAtIso,
    isTripartite: forceTripartiteLayout
        ? true
        : forceNormalLayout
            ? false
            : data.isTripartite,
    isTrueTripartite: data.isContingent,
    tripartiteRole: forceTripartiteLayout
        ? 'receipt'
        : forceNormalLayout
            ? null
            : data.tripartiteRole,
    linkedPartyName: data.linkedPartyName,
    senderSignatureHex: data.senderSignatureHex,
    receiverSignatureHex: data.receiverSignatureHex,
    senderPublicKeyHex: data.senderPublicKeyHex,
    receiverPublicKeyHex: data.receiverPublicKeyHex,
    senderStatusCode: data.senderStatusCode,
    receiverStatusCode: data.receiverStatusCode,
    counterpartyBalances: data.counterpartyBalances,
    counterpartyNature: data.counterpartyNature,
    affectedNature: data.affectedNature,
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

      if (data.isTripartite) {
        final isReceiptLeg = data.tripartiteRole == 'receipt' ||
            data.tripartiteRole == 'intermediary_receipt';
        final sender = isReceiptLeg
            ? data.counterpartyName
            : (data.linkedPartyName ?? AppStrings.sender);
        final receiver = isReceiptLeg
            ? (data.linkedPartyName ?? AppStrings.recipient)
            : data.counterpartyName;

        final shortId = data.id.length > 8 ? data.id.substring(0, 8) : data.id;
        shareText = AppStrings.voucherTripartiteShareText(
            sender, receiver, amountTextFormatter, data.referenceNumber ?? shortId);
      } else {
        final voucherType = data.typeCode == 'receipt'
            ? AppStrings.receiptNotice
            : AppStrings.disbursementNotice;
        final shortId = data.id.length > 8 ? data.id.substring(0, 8) : data.id;
        shareText = AppStrings.voucherStandardShareText(
            voucherType, data.counterpartyName, amountTextFormatter);

        shareText += AppStrings.shareTextAccount(data.affectedName);
        if (data.description != null && data.description!.isNotEmpty) {
          shareText += AppStrings.shareTextDescription(data.description!);
        }

        final balanceParts = data.counterpartyBalances.entries.map((e) {
          final digits = (e.key == data.currencyCode) ? data.currencyDigits : 2;
          final divisor =
              (digits == 0 ? 1 : (digits == 2 ? 100 : 1000)).toDouble();
          final value = e.value / divisor;
          final absValue = value.abs();
          final label = data.counterpartyNature == 'debit'
              ? value > 0
                  ? AppStrings.onYou
                  : AppStrings.your
              : value < 0
                  ? AppStrings.onYou
                  : AppStrings.your;
          return '${MoneyFormatter.formatDecimal(absValue, minimumFractionDigits: digits, maximumFractionDigits: digits)} ${CurrencyUtil.getLocalizedName(e.key)} $label'
              .trim();
        }).toList();
        if (balanceParts.isNotEmpty) {
          shareText += AppStrings.shareTextNetBalance(balanceParts.join(", "));
        }

        shareText +=
            AppStrings.shareTextReference(data.referenceNumber ?? shortId);
      }
      if (data.senderSignatureHex != null ||
          data.receiverSignatureHex != null) {
        shareText += AppStrings.shareTextVerificationFingerprint(
            data.senderSignatureHex ?? data.receiverSignatureHex!);
      }
    }

    // Preview and edit Step
    final editedText = await VoucherSharePreviewSheet.show(context, shareText);
    if (editedText == null) return; // Cancelled
    shareText = editedText;

    final method = await ShareMethodPicker.show(context);
    if (method == null) return;

    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'qayd_voucher_${data.id}.pdf');
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    if (method == ShareMethod.system) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/pdf')],
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
        fileAbsolutePath: path,
        phoneNumber: phoneNumber,
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(AppStrings.exportPdfShareError)),
    );
  }
}
