import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:qayd/application/accounts/dtos/get_account_details_input.dart';
import 'package:qayd/data/messaging/messaging_intent_launcher.dart';
import 'package:qayd/presentation/utils/whatsapp_flavor_picker.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;

import 'package:qayd/application/accounts/dtos/account_statement_chat_message_dto.dart';
import 'package:qayd/application/accounts/dtos/statement_chat_filter_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/dtos/account_statement_report_dto.dart';
import 'package:qayd/data/export/qayd_excel_workbook.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/utils/share_pdf_bytes.dart';
import 'package:qayd/core/utils/text_sanitizer.dart';

/// Exports the Statement of Account Chat as PDF using applied filters.
Future<void> shareStatementChatAsPdf(
  BuildContext context, {
  required String accountId,
  required String accountName,
  required StatementChatFilterInput filter,
  required List<AccountStatementChatMessageDto> messages,
  required Map<String, int> broughtForwardByCurrency,
  required Map<String, int> finalBalanceByCurrency,
  ShareMethod? shareMethod,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  final method = shareMethod ?? await ShareMethodPicker.show(context);
  if (method == null) return;

  if (!context.mounted) return;
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

  final now = DateTime.now().toIso8601String();
  final lines = <AccountStatementLineReportDto>[];

  // Add Brought Forward Balances
  if (filter.includePreviousBalance && filter.fromDate != null) {
    broughtForwardByCurrency.forEach((code, amount) {
      if (amount == 0) return;
      bool isPositive = amount >= 0;
      lines.add(
        AccountStatementLineReportDto(
          dateIso: filter.fromDate!.toIso8601String(),
          description: '${AppStrings.statementBroughtForward} ($code)',
          debitMinorUnits: isPositive ? 0 : amount.abs(),
          creditMinorUnits: isPositive ? amount : 0,
          balanceMinorUnits: amount,
          voucherId: '-',
          currencyCode: code,
          currencySymbol: code, // Fallback to code as symbol for BF
          currencyDigits: 2, // BF usually in standard digits or same as msg
        ),
      );
    });
  }

  // Add Messages
  lines.addAll(messages.map((m) {
    final isIncoming = m.direction == 'incoming';
    return AccountStatementLineReportDto(
      dateIso: m.dateIso,
      description: TextSanitizer.sanitizeText(m.description),
      debitMinorUnits: isIncoming ? 0 : m.amountMinorUnits,
      creditMinorUnits: isIncoming ? m.amountMinorUnits : 0,
      balanceMinorUnits: m.runningBalanceMinorUnits,
      voucherId: m.voucherId,
      currencyCode: m.currencyCode,
      currencySymbol: m.currencySymbol,
      currencyDigits: m.currencyDigits,
    );
  }));

  final safeAccountName = TextSanitizer.sanitizeText(accountName);

  final dto = AccountStatementReportDto(
    accountId: accountId,
    accountName: safeAccountName,
    natureCode:
        'credit', // In chat context, usually context-dependent, but 'credit' is safe fallback
    generatedAtIso: now,
    periodFromIso: filter.fromDate?.toIso8601String(),
    periodToIso: filter.toDate?.toIso8601String(),
    lines: lines,
    finalBalancesByCurrency: finalBalanceByCurrency,
  );

  final pdfR = await InjectionContainer.accountStatementPdfGenerator
      .buildStatementPdf(dto);

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

  if (pdfR.isFailure) {
    messenger.showSnackBar(
      SnackBar(content: Text(pdfR.failureOrNull!.messageAr)),
    );
    return;
  }

  try {
    final safeName = 'qayd_statement_$accountId.pdf';
    final bytes = pdfR.valueOrNull!;

    if (method == ShareMethod.system) {
      await sharePdfBytes(bytes, safeName);
    } else {
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, safeName);
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      final flavor = method == ShareMethod.whatsappStandard
          ? WhatsAppFlavor.standard
          : WhatsAppFlavor.business;

      String? phoneNumber;
      final aR = await InjectionContainer.getAccountDetailsUseCase(
        GetAccountDetailsInput(accountId: accountId),
      );
      if (aR.isSuccess) {
        phoneNumber =
            aR.valueOrNull!.whatsappNumber ?? aR.valueOrNull!.phoneNumber;
      }

      final shareText =
          'مرفق لكم كشف حساب $safeAccountName.\n\nموثق رقمياً عبر نظام قيد.';

      await MessagingIntentLauncher.shareToWhatsApp(
        flavor: flavor,
        message: shareText,
        fileAbsolutePath: file.path,
        phoneNumber: phoneNumber,
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(AppStrings.exportPdfShareError)),
    );
  }
}

/// Exports the Statement of Account Chat as Excel using applied filters.
///
/// The generated Excel file matches the professional branded template with
/// header bar, info section, styled transaction table, and totals.
Future<void> shareStatementChatAsExcel(
  BuildContext context, {
  required String accountId,
  required String accountName,
  required StatementChatFilterInput filter,
  required List<AccountStatementChatMessageDto> messages,
  required Map<String, int> broughtForwardByCurrency,
  required int currencyDigits,
  ShareMethod? shareMethod,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  final method = shareMethod ?? await ShareMethodPicker.show(context);
  if (method == null) return;

  if (!context.mounted) return;
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

  try {
    final headers = <String>[
      AppStrings.theDate,
      AppStrings.bondNumber,
      AppStrings.type,
      AppStrings.theCondition,
      AppStrings.creditor,
      AppStrings.debtor,
      AppStrings.balance,
    ];

    num divisor = 1;
    for (var i = 0; i < currencyDigits; i++) {
      divisor *= 10;
    }

    final rows = <List<Object?>>[];
    final dateFmtAr = DateFormat.yMMMd('en');

    int totalDebitMinor = 0;
    int totalCreditMinor = 0;

    // Brought Forward
    if (filter.includePreviousBalance && filter.fromDate != null) {
      broughtForwardByCurrency.forEach((code, amount) {
        if (amount == 0) return;
        final isPositive = amount >= 0;
        final bfMinorAbs = amount.abs() / divisor;
        final balance = amount / divisor;
        final debitVal = isPositive ? 0 : bfMinorAbs;
        final creditVal = isPositive ? bfMinorAbs : 0;

        rows.add([
          dateFmtAr.format(filter.fromDate!),
          '-',
          '${AppStrings.statementBroughtForward} ($code)',
          '-',
          debitVal == 0 ? '' : _fmtNum(debitVal, currencyDigits),
          creditVal == 0 ? '' : _fmtNum(creditVal, currencyDigits),
          _fmtNum(balance, currencyDigits),
        ]);

        if (!isPositive) {
          totalDebitMinor += amount.abs();
        } else {
          totalCreditMinor += amount;
        }
      });
    }

    rows.addAll(messages.map((m) {
      final dateStr = dateFmtAr.format(DateTime.parse(m.dateIso));
      final isIncoming = m.direction == 'incoming';

      final amount = m.amountMinorUnits / divisor;
      final balance = m.runningBalanceMinorUnits / divisor;

      final typeLabel = m.typeCode == 'receipt'
          ? AppStrings.voucherTypeReceipt
          : AppStrings.voucherTypePayment;

      final statusLabel = switch (m.signatureStatusCode) {
        'accepted' => AppStrings.statementStatusConfirmed,
        'underRequest' => AppStrings.statementStatusPending,
        'rejected' => AppStrings.statementStatusRejected,
        'unverified' => AppStrings.agreementUnverified,
        _ => m.signatureStatusCode,
      };

      // Track totals
      if (isIncoming) {
        totalCreditMinor += m.amountMinorUnits;
      } else {
        totalDebitMinor += m.amountMinorUnits;
      }

      return [
        dateStr,
        m.voucherId.length > 10
            ? '${m.voucherId.substring(0, 8)}…'
            : m.voucherId,
        typeLabel,
        statusLabel,
        isIncoming ? '' : _fmtNum(amount, currencyDigits),
        isIncoming ? _fmtNum(amount, currencyDigits) : '',
        _fmtNum(balance, currencyDigits),
      ];
    }));

    // Format totals
    final totalDebitStr = _fmtNum(totalDebitMinor / divisor, currencyDigits);
    final totalCreditStr = _fmtNum(totalCreditMinor / divisor, currencyDigits);
    final netBalanceMinor = totalCreditMinor - totalDebitMinor;
    final netBalanceStr = _fmtNum(netBalanceMinor / divisor, currencyDigits);

    // Format dates for meta
    final stmtDate = dateFmtAr.format(DateTime.now());
    String? periodFromStr;
    String? periodToStr;
    if (filter.fromDate != null) {
      periodFromStr = dateFmtAr.format(filter.fromDate!);
    }
    if (filter.toDate != null) {
      periodToStr = dateFmtAr.format(filter.toDate!);
    }

    final safeAccountName = TextSanitizer.sanitizeText(accountName);

    final openingBalanceStr = broughtForwardByCurrency.isEmpty
        ? null
        : broughtForwardByCurrency.entries
            .where((e) => e.value != 0)
            .map((e) =>
                '${e.key}: ${_fmtNum(e.value / divisor, currencyDigits)}')
            .join(' | ');

    // Use Isolate to prevent dropping frames on the main thread
    final bytes =
        await Isolate.run(() => QaydExcelWorkbook.buildAccountStatement(
              accountName: safeAccountName,
              headers: headers,
              rows: rows,
              counterpartyName: safeAccountName,
              statementDate: stmtDate,
              referenceNumber: accountId.length > 12
                  ? accountId.substring(0, 12)
                  : accountId,
              openingBalance: openingBalanceStr,
              periodFrom: periodFromStr,
              periodTo: periodToStr,
              totalDebit: totalDebitStr,
              totalCredit: totalCreditStr,
              netBalance: netBalanceStr,
              notesText:
                  AppStrings.thankYouForDealing,
            ));

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

    final safeName = 'qayd_statement_$accountId.xlsx';
    if (method == ShareMethod.system) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes,
                name: safeName,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
          ],
        ),
      );
    } else {
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, safeName);
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      // ─── Excel: two-step WhatsApp sharing ──────────────────────────────
      // WhatsApp refuses to accept EXTRA_TEXT alongside EXTRA_STREAM for
      // spreadsheet MIME types — it drops the file and shows only the text.
      //
      // Strategy:
      //   Step 1 — send the file via JID (no EXTRA_TEXT).
      //            WhatsApp opens the correct contact's chat with the file
      //            ready to send. User taps ▶ once.
      //   Step 2 — after 1.5 s, open the same contact via wa.me URL with the
      //            descriptive text pre-filled in the input box.
      //            User taps ▶ once more to send the caption.
      final flavor = method == ShareMethod.whatsappBusiness
          ? WhatsAppFlavor.business
          : WhatsAppFlavor.standard;

      String? phoneNumber;
      final aR = await InjectionContainer.getAccountDetailsUseCase(
        GetAccountDetailsInput(accountId: accountId),
      );
      if (aR.isSuccess) {
        phoneNumber =
            aR.valueOrNull!.whatsappNumber ?? aR.valueOrNull!.phoneNumber;
      }

      // Step 1: send the file (no message → WhatsApp keeps the attachment)
      await MessagingIntentLauncher.shareToWhatsApp(
        flavor: flavor,
        message: null,
        fileAbsolutePath: file.path,
        phoneNumber: phoneNumber,
      );

      // Step 2: after the file intent fires and WhatsApp moves to foreground,
      // pre-fill the descriptive caption via wa.me URL.
      final shareText =
          'مرفق لكم كشف حساب $safeAccountName (Excel).\n\nموثق رقمياً عبر نظام قيد.';
      await Future.delayed(const Duration(milliseconds: 1500));
      await MessagingIntentLauncher.openWhatsAppTextOnly(
        flavor,
        shareText,
        phoneNumber: phoneNumber,
      );
    }
  } catch (_) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true)
          .pop(); // dismiss loading if error
    }
    messenger.showSnackBar(
       SnackBar(content: Text(AppStrings.anErrorOccurredWhile1)),
    );
  }
}

/// Formats a number with the correct number of decimal places.
String _fmtNum(num value, int digits) {
  return NumberFormat('#,##0.${'0' * digits}', 'en').format(value);
}
