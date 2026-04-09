/// Minimal financial facts of a receipt that are included in the signed payload.
///
/// Description, notes, tags, and other mutable metadata are intentionally
/// excluded so that the signature remains valid even when those fields differ
/// between sender and receiver.
final class SignableReceipt {
  const SignableReceipt({
    required this.amountMinor,
    required this.currencyCode,
    required this.senderPhone,
    required this.receiverPhone,
    required this.dateIso,
    required this.receiptUuid,
    this.originalSourceName,
    this.finalBeneficiaryName,
    this.parentReceiptHash,
  });

  /// Amount in the currency's minor units (e.g. cents, fils).
  final int amountMinor;

  /// ISO 4217 currency code (e.g. 'YER', 'USD').
  final String currencyCode;

  /// Phone number of the party who sent the payment.
  final String senderPhone;

  /// Phone number of the party who received the payment and signs.
  final String receiverPhone;

  /// ISO 8601 date string (YYYY-MM-DD) — date only, no time component.
  final String dateIso;

  /// UUID of the receipt — unique reference preventing replay.
  final String receiptUuid;

  // ── Tripartite transfer enrichment ─────────────────────────────────────

  /// Name of the original source (Party A) in a tripartite transfer.
  /// Present only on the payment leg (C→B) so B knows where funds originate.
  final String? originalSourceName;

  /// Name of the final beneficiary (Party B) in a tripartite transfer.
  /// Present only on the receipt leg (A→C) so A knows where funds are going.
  final String? finalBeneficiaryName;

  /// SHA-256 hash (hex) of the parent receipt's canonical payload.
  /// Present only on the payment voucher — creates a cryptographic chain
  /// proving the payment to B is backed by the receipt from A.
  final String? parentReceiptHash;

  /// Builds the deterministic canonical payload string.
  ///
  /// V1 format: `QAYD_RECEIPT_V1|amount|currency|sender|receiver|date|uuid`
  /// V2 format (tripartite): `QAYD_RECEIPT_V2|amount|currency|sender|receiver|date|uuid|source|beneficiary|parentHash`
  ///
  /// This string is what gets hashed (SHA-256) and then signed.
  String get canonicalPayload {
    if (originalSourceName != null ||
        finalBeneficiaryName != null ||
        parentReceiptHash != null) {
      return 'QAYD_RECEIPT_V2'
          '|$amountMinor'
          '|$currencyCode'
          '|$senderPhone'
          '|$receiverPhone'
          '|$dateIso'
          '|$receiptUuid'
          '|${originalSourceName ?? ''}'
          '|${finalBeneficiaryName ?? ''}'
          '|${parentReceiptHash ?? ''}';
    }
    return 'QAYD_RECEIPT_V1|$amountMinor|$currencyCode|$senderPhone|$receiverPhone|$dateIso|$receiptUuid';
  }

  @override
  String toString() => 'SignableReceipt($amountMinor $currencyCode, $dateIso)';
}
