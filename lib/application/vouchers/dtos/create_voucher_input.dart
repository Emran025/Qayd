import 'package:image_picker/image_picker.dart';
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
    this.transferGroupId,
    this.tripartiteRole,
    this.linkedPartyId,
    this.isContingent = false,
    this.attachments = const [],
    this.originVoucherId,
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
  final String? transferGroupId;
  final String? tripartiteRole;
  final String? linkedPartyId;
  final bool isContingent;
  final List<XFile> attachments;
  final String? originVoucherId;
}
