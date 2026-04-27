import 'dart:io';
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
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/utils/share_pdf_bytes.dart';

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
    builder: (ctx) => const Center(
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
          description: '${AppStringsAr.statementBroughtForward} ($code)',
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
      description: m.description,
      debitMinorUnits: isIncoming ? 0 : m.amountMinorUnits,
      creditMinorUnits: isIncoming ? m.amountMinorUnits : 0,
      balanceMinorUnits: m.runningBalanceMinorUnits,
      voucherId: m.voucherId,
      currencyCode: m.currencyCode,
      currencySymbol: m.currencySymbol,
      currencyDigits: m.currencyDigits,
    );
  }));

  final dto = AccountStatementReportDto(
    accountId: accountId,
    accountName: accountName,
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
          'مرفق لكم كشف حساب $accountName.\n\nموثق رقمياً عبر نظام قيد.';

      await MessagingIntentLauncher.shareToWhatsApp(
        flavor: flavor,
        message: shareText,
        fileAbsolutePath: file.path,
        phoneNumber: phoneNumber,
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(AppStringsAr.exportPdfShareError)),
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
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final headers = [
      'التاريخ',
      'رقم السند',
      'النوع',
      'الحالة',
      'دائن',
      'مدين',
      'الرصيد',
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
          '${AppStringsAr.statementBroughtForward} ($code)',
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
          ? AppStringsAr.voucherTypeReceipt
          : AppStringsAr.voucherTypePayment;

      final statusLabel = switch (m.signatureStatusCode) {
        'accepted' => AppStringsAr.statementStatusConfirmed,
        'underRequest' => AppStringsAr.statementStatusPending,
        'rejected' => AppStringsAr.statementStatusRejected,
        'unverified' => AppStringsAr.agreementUnverified,
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

    final bytes = QaydExcelWorkbook.buildAccountStatement(
      accountName: accountName,
      headers: headers,
      rows: rows,
      counterpartyName: accountName,
      statementDate: stmtDate,
      referenceNumber:
          accountId.length > 12 ? accountId.substring(0, 12) : accountId,
      openingBalance: broughtForwardByCurrency.isEmpty
          ? null
          : broughtForwardByCurrency.entries
              .where((e) => e.value != 0)
              .map((e) =>
                  '${e.key}: ${_fmtNum(e.value / divisor, currencyDigits)}')
              .join(' | '),
      periodFrom: periodFromStr,
      periodTo: periodToStr,
      totalDebit: totalDebitStr,
      totalCredit: totalCreditStr,
      netBalance: netBalanceStr,
      notesText: 'شكراً لتعاملكم معنا!\nيرجى مراجعة الأرصدة والتأكد من صحتها.',
    );

    final dir = await getTemporaryDirectory();
    final safeName = 'qayd_statement_$accountId.xlsx';
    final path = p.join(dir.path, safeName);
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(path,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        ],
      ),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('حدث خطأ أثناء تصدير Excel')),
    );
  }
}

/// Formats a number with the correct number of decimal places.
String _fmtNum(num value, int digits) {
  return NumberFormat('#,##0.${'0' * digits}', 'en').format(value);
}
