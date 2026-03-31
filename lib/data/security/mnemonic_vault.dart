import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';

/// Encrypted local storage for the cryptographic identity seed and key pair.
///
/// Follows the established [LicenseVault] pattern — all entries live in
/// platform-backed secure storage (Keystore on Android, Keychain on iOS).
///
/// The mnemonic is the single source of truth. The key pair is cached for
/// performance but can always be re-derived from the mnemonic.
final class MnemonicVault {
  MnemonicVault({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Storage keys
  static const _kMnemonic = 'qayd_mnemonic_phrase_v1';
  static const _kPublicKey = 'qayd_crypto_public_key_v1';
  static const _kPrivateKey = 'qayd_crypto_private_key_v1';
  static const _kKeyGeneration = 'qayd_crypto_key_generation_v1';
  static const _kBackupConfirmed = 'qayd_mnemonic_backup_confirmed_v1';

  // ── Mnemonic ──────────────────────────────────────────────────────────────

  /// Reads the stored mnemonic phrase. Returns `null` if not yet generated.
  Future<MnemonicPhrase?> readMnemonic() async {
    final phrase = await _storage.read(key: _kMnemonic);
    if (phrase == null || phrase.isEmpty) return null;
    try {
      return MnemonicPhrase.fromPhrase(phrase);
    } catch (_) {
      return null;
    }
  }

  /// Stores the mnemonic phrase in encrypted storage.
  Future<void> writeMnemonic(MnemonicPhrase mnemonic) =>
      _storage.write(key: _kMnemonic, value: mnemonic.phrase);

  // ── Key pair ──────────────────────────────────────────────────────────────

  /// Reads the cached key pair from storage. Returns `null` if not stored.
  Future<CryptoKeyPair?> readKeyPair() async {
    final pubHex = await _storage.read(key: _kPublicKey);
    final privHex = await _storage.read(key: _kPrivateKey);
    if (pubHex == null || privHex == null) return null;
    if (pubHex.isEmpty || privHex.isEmpty) return null;
    try {
      return CryptoKeyPair.fromHex(
        privateKeyHex: privHex,
        publicKeyHex: pubHex,
      );
    } catch (_) {
      return null;
    }
  }

  /// Caches the derived key pair in encrypted storage.
  Future<void> writeKeyPair(CryptoKeyPair keyPair) async {
    await _storage.write(key: _kPublicKey, value: keyPair.publicKeyHex);
    await _storage.write(key: _kPrivateKey, value: keyPair.privateKeyHex);
  }

  // ── Key generation (rotation counter) ─────────────────────────────────────

  /// Reads the current key generation number (starts at 1).
  Future<int> readKeyGeneration() async {
    final raw = await _storage.read(key: _kKeyGeneration);
    if (raw == null) return 1;
    return int.tryParse(raw) ?? 1;
  }

  /// Writes the key generation number.
  Future<void> writeKeyGeneration(int generation) =>
      _storage.write(key: _kKeyGeneration, value: generation.toString());

  // ── Backup status ─────────────────────────────────────────────────────────

  /// Whether the user has confirmed they backed up their mnemonic.
  Future<bool> isBackupConfirmed() async {
    final raw = await _storage.read(key: _kBackupConfirmed);
    return raw == 'true';
  }

  /// Marks the mnemonic backup as confirmed by the user.
  Future<void> confirmBackup() =>
      _storage.write(key: _kBackupConfirmed, value: 'true');

  // ── Aggregate queries ─────────────────────────────────────────────────────

  /// Whether a cryptographic identity has been set up.
  Future<bool> hasIdentity() async {
    final kp = await readKeyPair();
    return kp != null;
  }

  // ── Wipe ──────────────────────────────────────────────────────────────────

  /// Wipes all identity data. Used by PanicWipeService.
  Future<void> deleteAll() async {
    await _storage.delete(key: _kMnemonic);
    await _storage.delete(key: _kPublicKey);
    await _storage.delete(key: _kPrivateKey);
    await _storage.delete(key: _kKeyGeneration);
    await _storage.delete(key: _kBackupConfirmed);
  }
}
