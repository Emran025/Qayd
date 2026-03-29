import 'package:qayd/domain/value_objects/voucher_type.dart';

class CreateVoucherInput {
  const CreateVoucherInput({
    required this.type,
    required this.date,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.counterpartyAccountId,
    required this.affectedAccountId,
    this.referenceNumber,
    this.description,
    this.notes,
  });

  final VoucherType type;
  final DateTime date;
  final int amountMinorUnits;
  final String currencyCode;
  final String counterpartyAccountId;
  final String affectedAccountId;
  final String? referenceNumber;
  final String? description;
  final String? notes;
}
