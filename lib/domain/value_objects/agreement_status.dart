/// Agreement state between parties for a financial voucher.
///
/// Handles the "Electronic Signature" aspect: Accepted, Rejected, or Under Request.
enum AgreementStatus {
  /// (تحت الطلب / بانتظار الموافقة) - Initial state, no valid signature yet.
  underRequest,

  /// (مقبول) - Digitally signed and verified against an authorized public key.
  accepted,

  /// (مرفوض) - Explicitly rejected by the counterparty.
  rejected,

  /// (غير مؤكد) - Signature present but does not match any current or previous key.
  unverified;

  bool get isUnderRequest => this == AgreementStatus.underRequest;
  bool get isAccepted => this == AgreementStatus.accepted;
  bool get isRejected => this == AgreementStatus.rejected;
  bool get isUnverified => this == AgreementStatus.unverified;
}
