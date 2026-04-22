import 'package:image_picker/image_picker.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

class CostCenterTagInput {
  const CostCenterTagInput({
    required this.costCenterId,
    this.dimensionIds = const [],
  });

  final String costCenterId;
  final List<String> dimensionIds;
}

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
    this.mediatorAccountId,
    this.feeAmountMinorUnits,
    this.isContingent = false,
    this.attachments = const [],
    this.originVoucherId,
    this.editingVoucherId,
    this.confirm = false,
    this.costCenterTags = const [],
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
  final String? mediatorAccountId;
  final int? feeAmountMinorUnits;
  final bool isContingent;
  final List<XFile> attachments;
  final String? originVoucherId;
  final String? editingVoucherId;

  /// If true, the voucher is immediately confirmed (signed) and enqueued for sync.
  final bool confirm;

  /// Optional cost center and dimension tags for analytical tracking.
  final List<CostCenterTagInput> costCenterTags;
}
