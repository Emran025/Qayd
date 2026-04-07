/// License lifecycle state.
enum LicenseStatus {
  /// Not yet provisioned — first run, needs API login.
  pending,

  /// 30-day trial active.
  trial,

  /// Trial period has ended — hard block.
  trialExpired,

  /// Full license active.
  active,

  /// Admin-suspended — read-only mode (handled by GovernanceCubit).
  suspended,

  /// Admin-revoked (FORCE_REVOKE) — hard block + panic wipe.
  revoked,

  /// Hardware ID mismatch — device is not the bound device.
  deviceUnbound,
}

/// Monotonic clock integrity status.
enum ClockStatus {
  /// No tampering detected.
  clean,

  /// System clock moved backwards — hard lock triggered.
  tampered,
}

class SecurityState {
  const SecurityState({
    this.licenseStatus = LicenseStatus.active,
    this.clockStatus = ClockStatus.clean,
    this.trialDaysRemaining,
  });

  final LicenseStatus licenseStatus;
  final ClockStatus clockStatus;
  final int? trialDaysRemaining;

  /// True when PIN lock screen should be shown.
  bool get isLocked => this is SecurityLocked;

  /// True when the entire app must be hard-blocked regardless of PIN.
  bool get isHardBlocked =>
      clockStatus == ClockStatus.tampered ||
      licenseStatus == LicenseStatus.trialExpired ||
      licenseStatus == LicenseStatus.revoked ||
      licenseStatus == LicenseStatus.deviceUnbound;

  /// True when any form of blocking overlay must be shown.
  bool get requiresOverlay => isLocked || isHardBlocked;
}

class SecurityUnlocked extends SecurityState {
  const SecurityUnlocked({
    super.licenseStatus = LicenseStatus.active,
    super.clockStatus = ClockStatus.clean,
    super.trialDaysRemaining,
  });
}

class SecurityLocked extends SecurityState {
  const SecurityLocked({
    super.licenseStatus = LicenseStatus.active,
    super.clockStatus = ClockStatus.clean,
    super.trialDaysRemaining,
  });
}
