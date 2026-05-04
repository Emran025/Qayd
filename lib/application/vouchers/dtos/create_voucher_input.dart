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
    this.collateral,
    this.senderSignatureHex,
    this.senderPublicKeyHex,
    this.receiverSignatureHex,
    this.receiverPublicKeyHex,
    this.qrSignerPhone,
    this.qrReceiverPhone,
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

  /// Optional collateral (رهن / ضمان) details.
  final CreateCollateralInput? collateral;

  // Digital signature fields from QR
  final String? senderSignatureHex;
  final String? senderPublicKeyHex;
  final String? receiverSignatureHex;
  final String? receiverPublicKeyHex;

  /// Phone of the QR issuer (Party A — the original signer).
  /// Passed when creating a voucher from a scanned QR so that
  /// [canonicalSenderPhone] is set correctly on the resulting entity.
  final String? qrSignerPhone;

  /// Phone of the local user when creating from QR (Party B — the receiver).
  /// Combined with [qrSignerPhone] to fully populate the canonical phones.
  final String? qrReceiverPhone;
}

class CreateCollateralInput {
  const CreateCollateralInput({
    required this.description,
    required this.estimatedValueMinor,
    this.expiryDate,
    this.imagePaths = const [],
  });

  final String description;
  final int estimatedValueMinor;
  final DateTime? expiryDate;
  final List<String> imagePaths;
}
