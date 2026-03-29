import 'package:qayd/domain/value_objects/voucher_type.dart';

class UpdateDraftVoucherInput {
  const UpdateDraftVoucherInput({
    required this.voucherId,
    this.type,
    this.date,
    this.amountMinorUnits,
    this.currencyCode,
    this.counterpartyAccountId,
    this.affectedAccountId,
    this.referenceNumber,
    this.description,
    this.notes,
  });

  final String voucherId;
  final VoucherType? type;
  final DateTime? date;
  final int? amountMinorUnits;
  final String? currencyCode;
  final String? counterpartyAccountId;
  final String? affectedAccountId;
  final String? referenceNumber;
  final String? description;
  final String? notes;
}
