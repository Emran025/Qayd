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

  // ── Password recovery ─────────────────────────────────────────────────────
  static const String passwordEmail = '$v1/auth/password/email';
  static const String passwordReset = '$v1/auth/password/reset';

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

  // ── Support & Documents ─────────────────────────────────────────────────
  static const String documents = '$v1/documents';
  static const String supportTickets = '$v1/support/tickets';
}
