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
  static const String authProfile = '$v1/account/profile';

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

  // ── Sync (Phase 8 skeleton) ───────────────────────────────────────────────
  static const String syncUp = '$v1/sync/up';
  static const String syncDown = '$v1/sync/down';
}
