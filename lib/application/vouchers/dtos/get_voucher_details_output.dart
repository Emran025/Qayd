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
    this.hasCollateral = false,
    this.collateralDescription,
    this.collateralStatusCode,
    this.collateralValueMinor,
    this.collateralExpiryIso,
    this.successorVoucherId,
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
  final bool canApprove;
  final String? originVoucherId;

  // Attachments
  final int attachmentCount;

  // Collateral
  final bool hasCollateral;
  final String? collateralDescription;
  final String? collateralStatusCode;
  final int? collateralValueMinor;
  final String? collateralExpiryIso;

  // Threading (Protocol v1.3)
  final String? successorVoucherId;
}
