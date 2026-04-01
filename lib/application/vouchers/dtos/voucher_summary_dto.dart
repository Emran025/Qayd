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
    this.tripartiteRole,
    this.linkedPartyId,
    this.isContingent = false,
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
  
  // Tripartite Transfer
  final bool isTripartite;
  final String? tripartiteRole;
  final String? linkedPartyId;
  final bool isContingent;
}
