/// Snapshot for voucher PDF generation (data → PDF engine boundary).
class VoucherReportDto {
  const VoucherReportDto({
    required this.voucherId,
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
    this.isTrueTripartite = false,
    this.tripartiteRole,
    this.linkedPartyName,
    this.senderSignatureHex,
    this.receiverSignatureHex,
    this.senderPublicKeyHex,
    this.receiverPublicKeyHex,
    required this.senderStatusCode,
    required this.receiverStatusCode,
    this.counterpartyBalances = const {},
  });

  final String voucherId;
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

  /// QR payload (JSON with signature data); falls back to voucherId if null.
  final String? qrData;

  final String createdAtIso;
  final String? confirmedAtIso;
  final String? settledAtIso;

  // Tripartite transfer
  final bool isTripartite;
  final bool isTrueTripartite;

  /// 'receipt' → this leg is A→C, 'payment' → C→B.
  final String? tripartiteRole;

  /// The third party in the chain (B for receipt leg, A for payment leg).
  final String? linkedPartyName;

  // Dual digital signatures
  final String? senderSignatureHex;
  final String? receiverSignatureHex;
  final String? senderPublicKeyHex;
  final String? receiverPublicKeyHex;
  final String senderStatusCode;
  final String receiverStatusCode;

  /// Map of currency code to balance minor units.
  final Map<String, int> counterpartyBalances;
}
