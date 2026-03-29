/// Remote governance outcome for the tenant / installation (Phase 2).
enum GovernanceStatus {
  /// Full read/write access.
  activated,

  /// Read-only: writes must be rejected until status clears.
  suspended,

  /// Re-authentication required; app should collect activation credentials.
  revoked,
}
