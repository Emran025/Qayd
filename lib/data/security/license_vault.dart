import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted storage for license credentials and trial clock.
///
/// All entries live in [FlutterSecureStorage] (Keystore/Keychain-backed).
final class LicenseVault {
  LicenseVault({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Storage keys
  static const _kJwt = 'qayd_license_jwt_v1';
  static const _kServerSalt = 'qayd_license_server_salt_v1';
  static const _kLicenseData = 'qayd_license_data_v1';
  static const _kTrialStart = 'qayd_trial_start_epoch_v1';
  static const _kProvisionedHardwareId = 'qayd_provisioned_hw_id_v1';
  static const _kLocalDbSalt = 'qayd_local_db_salt_v1';

  static const int trialDurationDays = 30;

  // ── JWT ────────────────────────────────────────────────────────────────────

  Future<String?> readJwt() => _storage.read(key: _kJwt);
  Future<void> writeJwt(String jwt) => _storage.write(key: _kJwt, value: jwt);

  // ── Server-issued salt (for PBKDF2 key derivation) ─────────────────────────

  Future<String?> readServerSalt() => _storage.read(key: _kServerSalt);
  Future<void> writeServerSalt(String salt) =>
      _storage.write(key: _kServerSalt, value: salt);

  // ── Local DB salt (generated on first boot) ────────────────────────────────

  Future<String?> readLocalDbSalt() => _storage.read(key: _kLocalDbSalt);
  Future<void> writeLocalDbSalt(String salt) =>
      _storage.write(key: _kLocalDbSalt, value: salt);

  // ── License data (JSON blob from API) ─────────────────────────────────────

  Future<Map<String, dynamic>?> readLicenseData() async {
    final raw = await _storage.read(key: _kLicenseData);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeLicenseData(Map<String, dynamic> data) =>
      _storage.write(key: _kLicenseData, value: jsonEncode(data));

  // ── Trial clock ────────────────────────────────────────────────────────────

  Future<DateTime?> readTrialStart() async {
    final raw = await _storage.read(key: _kTrialStart);
    if (raw == null) return null;
    final epoch = int.tryParse(raw);
    if (epoch == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true);
  }

  Future<void> writeTrialStart(DateTime dt) => _storage.write(
        key: _kTrialStart,
        value: dt.millisecondsSinceEpoch.toString(),
      );

  bool isTrialExpired(DateTime trialStart) {
    final now = DateTime.now().toUtc();
    return now.difference(trialStart).inDays >= trialDurationDays;
  }

  int daysRemainingInTrial(DateTime trialStart) {
    final now = DateTime.now().toUtc();
    final elapsed = now.difference(trialStart).inDays;
    return (trialDurationDays - elapsed).clamp(0, trialDurationDays);
  }

  // ── Provisioned hardware ID ────────────────────────────────────────────────

  Future<String?> readProvisionedHardwareId() =>
      _storage.read(key: _kProvisionedHardwareId);

  Future<void> writeProvisionedHardwareId(String id) =>
      _storage.write(key: _kProvisionedHardwareId, value: id);

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<bool> isProvisioned() async {
    final jwt = await readJwt();
    return jwt != null && jwt.isNotEmpty;
  }

  /// Wipes all license-related entries. Used by PanicWipeService.
  Future<void> deleteAll() async {
    await _storage.delete(key: _kJwt);
    await _storage.delete(key: _kServerSalt);
    await _storage.delete(key: _kLicenseData);
    await _storage.delete(key: _kTrialStart);
    await _storage.delete(key: _kProvisionedHardwareId);
    await _storage.delete(key: _kLocalDbSalt);
  }
}
