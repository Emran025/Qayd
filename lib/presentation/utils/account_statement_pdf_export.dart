import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/get_account_statement_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/dtos/account_statement_report_dto.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/utils/share_pdf_bytes.dart';
import 'package:qayd/core/utils/text_sanitizer.dart';

/// Exports full account statement (all movements) as PDF and opens the share sheet.
Future<void> shareAccountStatementAsPdf(
  BuildContext context, {
  required String accountId,
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

  final stmtR = await InjectionContainer.getAccountStatementUseCase(
    GetAccountStatementInput(accountId: accountId),
  );

  if (!context.mounted) {
    return;
  }
  Navigator.of(context, rootNavigator: true).pop();

  if (stmtR.isFailure) {
    messenger.showSnackBar(
      SnackBar(content: Text(stmtR.failureOrNull!.messageAr)),
    );
    return;
  }

  final stmt = stmtR.valueOrNull!;
  final now = DateTime.now().toIso8601String();

  // Resolve issuer name: use company name or mediator name from settings
  final prefs = InjectionContainer.sharedPreferences;
  final issuerName = prefs.getString('company_name') ??
      prefs.getString('pdf_mediator_name') ??
      AppStringsAr.entryPersonalAccounting;

  final dto = AccountStatementReportDto(
    accountId: stmt.accountId,
    accountName: TextSanitizer.sanitizeText(stmt.accountName),
    natureCode: stmt.natureCode,
    generatedAtIso: now,
    issuerName: issuerName,
    lines: stmt.lines
        .map(
          (l) => AccountStatementLineReportDto(
            dateIso: l.dateIso,
            description: TextSanitizer.sanitizeText(l.description),
            debitMinorUnits: l.debitMinorUnits,
            creditMinorUnits: l.creditMinorUnits,
            balanceMinorUnits: l.balanceMinorUnits,
            voucherId: l.voucherId,
            currencyCode: l.currencyCode,
            currencySymbol: l.currencySymbol,
            currencyDigits: l.currencyDigits,
          ),
        )
        .toList(growable: false),
  );

  final pdfR =
      await InjectionContainer.accountStatementPdfGenerator.buildStatementPdf(
    dto,
  );

  if (!context.mounted) {
    return;
  }

  if (pdfR.isFailure) {
    messenger.showSnackBar(
      SnackBar(content: Text(pdfR.failureOrNull!.messageAr)),
    );
    return;
  }
  try {
    final safeName = 'qayd_statement_${stmt.accountId}.pdf';
    await sharePdfBytes(pdfR.valueOrNull!, safeName);
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(AppStringsAr.exportPdfShareError)),
    );
  }
}
