/// Cryptographic verification state of a receipt's digital signature.
///
/// - [unsigned]: No signature attached (draft by the payer).
/// - [signed]: Signature present but not yet verified against a known public key.
/// - [verified]: Signature mathematically verified against a registered public key.
/// - [invalid]: Signature verification failed — payload tampered or wrong key.
enum SignatureStatus {
  unsigned,
  signed,
  verified,
  invalid;

  bool get isUnsigned => this == SignatureStatus.unsigned;
  bool get isSigned => this == SignatureStatus.signed;
  bool get isVerified => this == SignatureStatus.verified;
  bool get isInvalid => this == SignatureStatus.invalid;

  /// Whether a valid cryptographic signature exists (signed or verified).
  bool get hasCryptographicSignature =>
      this == SignatureStatus.signed || this == SignatureStatus.verified;
}
