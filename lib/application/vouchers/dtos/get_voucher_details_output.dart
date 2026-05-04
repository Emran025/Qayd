class GetVoucherDetailsOutput {
  const GetVoucherDetailsOutput({
    required this.id,
    required this.typeCode,
    required this.stateCode,
    required this.dateIso,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.currencyNameAr,
    required this.currencySymbol,
    required this.currencyDigits,
    required this.counterpartyAccountId,
    required this.counterpartyName,
    required this.affectedAccountId,
    required this.affectedName,
    this.counterpartyNature,
    this.affectedNature,
    this.referenceNumber,
    this.description,
    this.notes,
    this.qrData,
    required this.createdAtIso,
    this.confirmedAtIso,
    this.settledAtIso,
    this.isTripartite = false,
    this.tripartiteRole,
    this.linkedPartyId,
    this.linkedPartyName,
    this.transferGroupId,
    this.isContingent = false,
    this.senderSignatureHex,
    this.receiverSignatureHex,
    this.senderPublicKeyHex,
    this.receiverPublicKeyHex,
    required this.senderStatusCode,
    required this.receiverStatusCode,
    this.canApprove = false,
    this.originVoucherId,
    this.attachmentCount = 0,
    this.attachments = const [],
    this.hasCollateral = false,
    this.collateralId,
    this.collateralDescription,
    this.collateralStatusCode,
    this.collateralValueMinor,
    this.collateralExpiryIso,
    this.collateralSettlementVoucherIds = const [],
    this.successorVoucherId,
    this.costCenters = const [],
    this.isCreator = true,
    this.counterpartyBalances = const {},
    this.isSenderSignatureVerified = false,
    this.isReceiverSignatureVerified = false,
  });

  final String id;
  final String typeCode;
  final String stateCode;
  final String dateIso;
  final int amountMinorUnits;
  final String currencyCode;
  final String currencyNameAr;
  final String currencySymbol;
  final int currencyDigits;
  final String counterpartyAccountId;
  final String counterpartyName;
  final String affectedAccountId;
  final String affectedName;
  final String? referenceNumber;
  final String? description;
  final String? notes;
  final String? qrData;
  final String createdAtIso;
  final String? confirmedAtIso;
  final String? settledAtIso;

  // Tripartite Transfer
  final bool isTripartite;
  final String? tripartiteRole;
  final String? linkedPartyId;
  final String? linkedPartyName;
  final String? transferGroupId;
  final bool isContingent;

  // Dual digital signatures
  final String? senderSignatureHex;
  final String? receiverSignatureHex;
  final String? senderPublicKeyHex;
  final String? receiverPublicKeyHex;
  final String senderStatusCode;
  final String receiverStatusCode;
  final bool isSenderSignatureVerified;
  final bool isReceiverSignatureVerified;
  final bool canApprove;
  final String? originVoucherId;

  // Attachments
  final int attachmentCount;
  final List<VoucherAttachmentSummary> attachments;

  // Collateral
  final bool hasCollateral;
  final String? collateralId;
  final String? collateralDescription;
  final String? collateralStatusCode;
  final int? collateralValueMinor;
  final String? collateralExpiryIso;

  /// Voucher IDs of settlement vouchers linked to this collateral.
  final List<String> collateralSettlementVoucherIds;

  // Threading (Protocol v1.3)
  final String? successorVoucherId;

  // Cost / Profit Centers
  final List<CostCenterSummary> costCenters;

  /// Whether the current user is the creator of this voucher
  final bool isCreator;

  /// The running balance of the counterparty at the time of this voucher.
  /// Key is currency code, value is minor units.
  final Map<String, int> counterpartyBalances;

  final String? counterpartyNature;
  final String? affectedNature;
}

/// Lightweight summary of an attachment for display in the detail view.
class VoucherAttachmentSummary {
  const VoucherAttachmentSummary({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.byteSize,
    required this.createdAtIso,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int byteSize;
  final String createdAtIso;
}

/// Lightweight summary of a cost/profit center association.
class CostCenterSummary {
  const CostCenterSummary({
    required this.id,
    required this.name,
    required this.typeCode,
    this.dimensions = const [],
  });

  final String id;
  final String name;

  /// 'cost' or 'profit'
  final String typeCode;

  final List<DimensionSummary> dimensions;
}

class DimensionSummary {
  const DimensionSummary({
    required this.id,
    required this.name,
    required this.categoryName,
  });

  final String id;
  final String name;
  final String categoryName;
}
