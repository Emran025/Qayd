class VoucherSummaryDto {
  const VoucherSummaryDto({
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
    this.isTripartite = false,
    this.transferGroupId,
    this.tripartiteRole,
    this.linkedPartyId,
    this.isContingent = false,
    required this.senderStatusCode,
    required this.receiverStatusCode,
    this.originVoucherId,
    this.reversalCount = 0,
    this.firstChildId,
    this.description,
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
  final String? description;
  
  // Tripartite Transfer
  final bool isTripartite;
  final String? transferGroupId;
  final String? tripartiteRole;
  final String? linkedPartyId;
  final bool isContingent;
  final String senderStatusCode;
  final String receiverStatusCode;
  final String? originVoucherId;
  final int reversalCount;
  final String? firstChildId;
}
