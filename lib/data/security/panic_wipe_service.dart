import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/data/security/monotonic_clock_guard.dart';
import 'package:qayd/data/security/app_pin_storage.dart';

/// Executes a full credential wipe when a FORCE_REVOKE or security breach
/// is detected. Destroys all key material and license data immediately.
final class PanicWipeService {
  PanicWipeService({
    required LicenseVault licenseVault,
    required MonotonicClockGuard clockGuard,
    required AppPinStorage pinStorage,
    FlutterSecureStorage? storage,
  })  : _licenseVault = licenseVault,
        _clockGuard = clockGuard,
        _pinStorage = pinStorage,
        _storage = storage ?? const FlutterSecureStorage();

  final LicenseVault _licenseVault;
  final MonotonicClockGuard _clockGuard;
  final AppPinStorage _pinStorage;
  final FlutterSecureStorage _storage;

  /// Wipe everything: JWT, salts, license data, PIN, clock guard.
  ///
  /// The database remains on disk but is rendered inaccessible because
  /// the derived key material has been destroyed.
  Future<void> wipeAll() async {
    await _licenseVault.deleteAll();
    await _clockGuard.delete();
    await _pinStorage.clearPinAndLock();
    // Nuclear option: wipe the entire secure storage namespace.
    // This catches any key material we may have missed.
    await _storage.deleteAll();
  }
}
