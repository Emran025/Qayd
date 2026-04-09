/// Remote governance outcome for the tenant / installation.
final class GovernanceStatus {
  const GovernanceStatus({
    required this.kind,
    this.ownerAccountNumber,
    this.expiryDate,
    this.messageAr,
  });

  /// The current state code.
  final GovernanceStatusKind kind;

  /// Optional account number for payment (if suspended/revoked/expired).
  final String? ownerAccountNumber;

  /// Optional expiry date of the current license / trial.
  final DateTime? expiryDate;

  /// Optional message from the server (e.g. reason for suspension).
  final String? messageAr;

  /// Shortcut for the most common state.
  static const GovernanceStatus activated =
      GovernanceStatus(kind: GovernanceStatusKind.activated);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GovernanceStatus &&
        kind == other.kind &&
        ownerAccountNumber == other.ownerAccountNumber &&
        expiryDate == other.expiryDate &&
        messageAr == other.messageAr;
  }

  @override
  int get hashCode =>
      Object.hash(kind, ownerAccountNumber, expiryDate, messageAr);
}

enum GovernanceStatusKind {
  /// Full read/write access.
  activated,

  /// Read-only: writes must be rejected until status clears.
  suspended,

  /// Re-authentication required; app should collect activation credentials.
  revoked,

  /// Hard lock: trial or license expired, must pay to continue.
  expired,
}
