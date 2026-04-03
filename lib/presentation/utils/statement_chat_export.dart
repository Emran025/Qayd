import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

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
  required int broughtForwardMinorUnits,
}) async {
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

  final now = DateTime.now().toIso8601String();
  final lines = <AccountStatementLineReportDto>[];

  // Add Brought Forward Balance
  if (filter.includePreviousBalance && broughtForwardMinorUnits != 0 && filter.fromDate != null) {
    bool isPositive = broughtForwardMinorUnits >= 0;
    lines.add(
      AccountStatementLineReportDto(
        dateIso: filter.fromDate!.toIso8601String(),
        description: AppStringsAr.statementBroughtForward,
        debitMinorUnits: isPositive ? 0 : broughtForwardMinorUnits.abs(),
        creditMinorUnits: isPositive ? broughtForwardMinorUnits : 0,
        balanceMinorUnits: broughtForwardMinorUnits,
        voucherId: '-',
      ),
    );
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
    );
  }));

  final dto = AccountStatementReportDto(
    accountId: accountId,
    accountName: accountName,
    natureCode: 'credit', // In chat context, usually context-dependent, but 'credit' is safe fallback
    generatedAtIso: now,
    periodFromIso: filter.fromDate?.toIso8601String(),
    periodToIso: filter.toDate?.toIso8601String(),
    lines: lines,
  );

  final pdfR = await InjectionContainer.accountStatementPdfGenerator.buildStatementPdf(dto);

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
    await sharePdfBytes(pdfR.valueOrNull!, safeName);
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(AppStringsAr.exportPdfShareError)),
    );
  }
}

/// Exports the Statement of Account Chat as Excel using applied filters.
Future<void> shareStatementChatAsExcel(
  BuildContext context, {
  required String accountId,
  required String accountName,
  required StatementChatFilterInput filter,
  required List<AccountStatementChatMessageDto> messages,
  required int broughtForwardMinorUnits,
  required int currencyDigits,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final headers = [
      'التاريخ',
      'رقم السند',
      'النوع',
      'الحالة',
      'مدين',
      'دائن',
      'الرصيد',
      'البيان',
    ];

    num divisor = 1;
    for (var i = 0; i < currencyDigits; i++) {
      divisor *= 10;
    }

    final rows = <List<Object?>>[];

    // Brought Forward
    if (filter.includePreviousBalance && broughtForwardMinorUnits != 0 && filter.fromDate != null) {
      final df = DateFormat.yMMMd('ar');
      final isPositive = broughtForwardMinorUnits >= 0;
      final bfMinorAbs = broughtForwardMinorUnits.abs() / divisor;
      final balance = broughtForwardMinorUnits / divisor;
      rows.add([
        df.format(filter.fromDate!),
        '-',
        '-',
        '-',
        isPositive ? 0 : bfMinorAbs,
        isPositive ? bfMinorAbs : 0,
        balance,
        AppStringsAr.statementBroughtForward,
      ]);
    }

    rows.addAll(messages.map((m) {
      final df = DateFormat.yMMMd('ar');
      final dateStr = df.format(DateTime.parse(m.dateIso));
      final isIncoming = m.direction == 'incoming';

      final amount = m.amountMinorUnits / divisor;
      final balance = m.runningBalanceMinorUnits / divisor;
      
      final typeLabel = m.typeCode == 'receipt' ? AppStringsAr.voucherTypeReceipt : AppStringsAr.voucherTypePayment;
      
      final statusLabel = switch (m.signatureStatusCode) {
        'accepted' => AppStringsAr.statementStatusConfirmed,
        'underRequest' => AppStringsAr.statementStatusPending,
        'rejected' => AppStringsAr.statementStatusRejected,
        'unverified' => AppStringsAr.agreementUnverified,
        _ => m.signatureStatusCode,
      };

      return [
        dateStr,
        m.voucherId,
        typeLabel,
        statusLabel,
        isIncoming ? 0 : amount,
        isIncoming ? amount : 0,
        balance,
        m.description,
      ];
    }));

    final bytes = QaydExcelWorkbook.buildAccountStatement(
      accountName: accountName,
      headers: headers,
      rows: rows,
    );

    final dir = await getTemporaryDirectory();
    final safeName = 'qayd_statement_$accountId.xlsx';
    final path = p.join(dir.path, safeName);
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('حدث خطأ أثناء تصدير Excel')),
    );
  }
}
