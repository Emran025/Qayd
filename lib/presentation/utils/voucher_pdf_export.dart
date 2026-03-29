import 'package:flutter/material.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/dtos/voucher_report_dto.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/utils/share_pdf_bytes.dart';

Future<void> shareVoucherAsPdf(
  BuildContext context,
  GetVoucherDetailsOutput data,
) async {
  final messenger = ScaffoldMessenger.of(context);
  await showDialog<void>(
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
    counterpartyAccountId: data.counterpartyAccountId,
    counterpartyName: data.counterpartyName,
    affectedAccountId: data.affectedAccountId,
    affectedName: data.affectedName,
    referenceNumber: data.referenceNumber,
    description: data.description,
    notes: data.notes,
    createdAtIso: data.createdAtIso,
    confirmedAtIso: data.confirmedAtIso,
    settledAtIso: data.settledAtIso,
  );

  final result = await InjectionContainer.voucherPdfGenerator.buildVoucherPdf(
    dto,
  );

  if (!context.mounted) {
    return;
  }
  Navigator.of(context, rootNavigator: true).pop();

  if (result.isFailure) {
    messenger.showSnackBar(
      SnackBar(content: Text(result.failureOrNull!.messageAr)),
    );
    return;
  }
  final bytes = result.valueOrNull!;
  try {
    await sharePdfBytes(bytes, 'qayd_voucher_${data.id}.pdf');
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(AppStringsAr.exportPdfShareError)),
    );
  }
}
