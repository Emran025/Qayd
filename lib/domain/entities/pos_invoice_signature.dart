/// Immutable signature metadata attached to a frozen POS invoice snapshot.
final class PosInvoiceSignature {
  const PosInvoiceSignature({
    required this.invoiceId,
    required this.signatureHex,
    required this.signerPublicKeyHex,
    required this.payloadHashHex,
    required this.signedAt,
  });

  final String invoiceId;
  final String signatureHex;
  final String signerPublicKeyHex;
  final String payloadHashHex;
  final DateTime signedAt;
}
