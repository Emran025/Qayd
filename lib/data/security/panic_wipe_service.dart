import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qayd/data/security/identity_file_storage.dart';
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
    IdentityFileStorage? identityFileStorage,
    FlutterSecureStorage? storage,
  })  : _licenseVault = licenseVault,
        _clockGuard = clockGuard,
        _pinStorage = pinStorage,
        _identityFileStorage = identityFileStorage,
        _storage = storage ?? const FlutterSecureStorage();

  final LicenseVault _licenseVault;
  final MonotonicClockGuard _clockGuard;
  final AppPinStorage _pinStorage;
  final IdentityFileStorage? _identityFileStorage;
  final FlutterSecureStorage _storage;

  /// Wipe everything: JWT, salts, license data, PIN, clock guard, identity file.
  ///
  /// The database remains on disk but is rendered inaccessible because
  /// the derived key material has been destroyed.
  Future<void> wipeAll() async {
    await _licenseVault.deleteAll();
    await _clockGuard.delete();
    await _pinStorage.clearPinAndLock();
    // Also delete the identity file so auto-restore cannot resurrect wiped keys.
    await _identityFileStorage?.delete();
    // Nuclear option: wipe the entire secure storage namespace.
    // This catches any key material we may have missed.
    await _storage.deleteAll();
  }
}
