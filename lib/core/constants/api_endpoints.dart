/// Centralized API endpoint path constants for qaydAPI v1.
///
/// Use these instead of hard-coding path strings in repositories.
/// All paths are relative to the base URL and do NOT include a leading slash.
///
/// Example:
/// ```dart
/// final uri = '$baseUrl/${ApiEndpoints.authLogin}';
/// ```
abstract final class ApiEndpoints {
  // ── Server base URL ───────────────────────────────────────────────────────
  /// Resolved at compile-time from the `QAYD_API_URL` env variable.
  /// Pass with: `--dart-define=QAYD_API_URL=https://api.qayd.app`
  /// Falls back to the Android emulator loopback address in development.
  static const String baseUrl = String.fromEnvironment(
    'QAYD_API_URL',
    defaultValue: 'https://qayd-qq6w.onrender.com/',
  );

  // ── Base prefix ───────────────────────────────────────────────────────────
  static const String v1 = '/api/v1';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String authLogin = '$v1/auth/login';
  static const String authRegister = '$v1/auth/register';
  static const String authLogout = '$v1/auth/logout';
  static String get authProfile => '$v1/account/profile';
  static String get authProfileUpdate => '$v1/account/profile/update';
  static String get authAccountDelete => '$v1/account/delete';

  // ── Password recovery ─────────────────────────────────────────────────────
  static const String passwordEmail = '$v1/auth/password/email';
  static const String passwordReset = '$v1/auth/password/reset';

  // ── Email verification ────────────────────────────────────────────────────
  static const String verificationSend =
      '$v1/auth/email/verification-notification';
  static const String verificationVerifyOtp = '$v1/auth/email/verify-otp';

  // ── License ───────────────────────────────────────────────────────────────
  static const String licenseVerify = '$v1/license/verify';
  static const String licenseRefresh = '$v1/license/refresh';

  // ── Identity (Cryptographic key registry) ────────────────────────────────
  static const String identityRegisterKey = '$v1/identity/register-key';
  static const String identityLookup = '$v1/identity/lookup';
  static const String identityLookupBatch = '$v1/identity/lookup-batch';
  static const String identityReverseLookup = '$v1/identity/reverse-lookup';

  // ── Sync (E2EE Nodes) ───────────────────────────────────────────────────
  static const String syncPush = '$v1/sync/push';
  static const String syncPull = '$v1/sync/pull';
  static const String syncAcknowledge = '$v1/sync/acknowledge';
  static const String devicesPair = '$v1/devices/pair';
  static const String devicesList = '$v1/devices';
  static const String devicesCompanionBootstrap =
      '$v1/devices/companion/bootstrap';
  static const String devicesCompanionConsume = '$v1/devices/companion/consume';
  static String deviceRevoke(String deviceId) => '$v1/devices/$deviceId/revoke';

  // ── Support & Documents ─────────────────────────────────────────────────
  static const String documents = '$v1/documents';
  static const String supportTickets = '$v1/support/tickets';

  // ── Sync Privacy (§6: Accounting Contacts) ────────────────────────────
  static const String syncPrivacyPolicy = '$v1/sync-privacy/policy';
  static const String syncPrivacyListAdd = '$v1/sync-privacy/list';
  static String syncPrivacyListRemove(int id) => '$v1/sync-privacy/list/$id';
}
