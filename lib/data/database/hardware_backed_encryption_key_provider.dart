import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qayd/data/database/database_encryption_key_provider.dart';
import 'package:qayd/data/security/hardware_id_service.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/data/security/pbkdf2_key_deriver.dart';

/// Production key provider: derives the SQLCipher passphrase via PBKDF2.
///
/// Entropy formula (from spec):
///   PBKDF2(Salt: ServerIssuedSalt + HardwareID, Iterations: 1000)
///
/// On first boot there is no server salt; a local random salt is generated
/// and persisted in [FlutterSecureStorage]. The derived key is stored
/// directly so the same passphrase is returned on every subsequent open
/// even before the device is provisioned.
final class HardwareBackedEncryptionKeyProvider
    implements DatabaseEncryptionKeyProvider {
  HardwareBackedEncryptionKeyProvider({
    required HardwareIdService hardwareIdService,
    required LicenseVault licenseVault,
    FlutterSecureStorage? storage,
  })  : _hardwareIdService = hardwareIdService,
        _licenseVault = licenseVault,
        _storage = storage ?? const FlutterSecureStorage();

  final HardwareIdService _hardwareIdService;
  final LicenseVault _licenseVault;
  final FlutterSecureStorage _storage;

  static const _kDerivedKey = 'qayd_db_derived_key_v2';

  @override
  Future<String> obtainKey() async {
    // Return cached derived key if available.
    final cached = await _storage.read(key: _kDerivedKey);
    if (cached != null && cached.isNotEmpty) return cached;

    // Derive and cache.
    final key = await _deriveKey();
    await _storage.write(key: _kDerivedKey, value: key);
    return key;
  }

  /// Explicitly derives a DB key from a mnemonic.
  /// Used during restoration if no key file is found.
  Future<String> deriveKeyFromMnemonic(String mnemonicPhrase) async {
    final hardwareId = await _hardwareIdService.obtainHardwareId();
    // Deterministic entropy based on mnemonic + hardwareId
    return Pbkdf2KeyDeriver.derive(
      password: mnemonicPhrase,
      salt: 'qayd_db_salt_$hardwareId',
    );
  }

  /// Updates the cached key in secure storage.
  /// Used after a successful restore with a custom key.
  Future<void> updateCachedKey(String key) async {
    await _storage.write(key: _kDerivedKey, value: key);
  }

  Future<String> _deriveKey() async {
    final hardwareId = await _hardwareIdService.obtainHardwareId();

    // Get or generate the local salt (persisted in secure storage).
    var localSalt = await _licenseVault.readLocalDbSalt();
    if (localSalt == null || localSalt.isEmpty) {
      localSalt = _generateRandomSalt();
      await _licenseVault.writeLocalDbSalt(localSalt);
    }

    // Combine with server-issued salt if available.
    final serverSalt = await _licenseVault.readServerSalt() ?? '';
    final combinedSalt = '$serverSalt$hardwareId$localSalt';

    return Pbkdf2KeyDeriver.derive(
      password: hardwareId,
      salt: combinedSalt,
    );
  }

  String _generateRandomSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
