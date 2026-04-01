import 'package:qayd/data/security/identity_file_storage.dart';
import 'package:qayd/data/security/mnemonic_vault.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/services/crypto_identity_service.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';

/// Orchestrates first-time identity setup or recovery:
///   1. Generates (or accepts) a mnemonic.
///   2. Derives the Ed25519 key pair.
///   3. Stores both locally in the vault (secure storage).
///   4. Persists both to the device identity file alongside the DB.
///   5. Registers the public key on the server.
final class SetupIdentityUseCase {
  const SetupIdentityUseCase({
    required CryptoIdentityService cryptoService,
    required MnemonicVault mnemonicVault,
    required IdentityRepository identityRepository,
    required IdentityFileStorage identityFileStorage,
  })  : _crypto = cryptoService,
        _vault = mnemonicVault,
        _identity = identityRepository,
        _fileStorage = identityFileStorage;

  final CryptoIdentityService _crypto;
  final MnemonicVault _vault;
  final IdentityRepository _identity;
  final IdentityFileStorage _fileStorage;

  /// Generates a new identity (first-time registration).
  ///
  /// Returns the mnemonic phrase that the user must back up.
  /// The key pair is derived, stored locally, persisted to file,
  /// and the public key is registered on the server.
  Future<MnemonicPhrase> generateAndRegister() async {
    final mnemonic = _crypto.generateMnemonic();
    final keyPair = _crypto.deriveKeyPair(mnemonic);

    await _vault.writeMnemonic(mnemonic);
    await _vault.writeKeyPair(keyPair);
    await _vault.writeKeyGeneration(1);

    // Persist to file alongside the database for auto-restore after reinstall.
    await _fileStorage.persist(mnemonic: mnemonic, keyPair: keyPair);

    // Register public key with server (best-effort; non-blocking).
    try {
      final generation = await _identity.registerPublicKey(
        publicKeyHex: keyPair.publicKeyHex,
      );
      await _vault.writeKeyGeneration(generation);
    } catch (_) {
      // Server registration will be retried on next app launch.
    }

    return mnemonic;
  }

  /// Recovers identity from a mnemonic phrase (device loss / migration).
  ///
  /// Derives the same key pair from the seed, re-registers with server,
  /// and refreshes the device identity file.
  Future<CryptoKeyPair> recoverFromMnemonic(MnemonicPhrase mnemonic) async {
    final keyPair = _crypto.deriveKeyPair(mnemonic);

    await _vault.writeMnemonic(mnemonic);
    await _vault.writeKeyPair(keyPair);

    // Refresh identity file after recovery.
    await _fileStorage.persist(mnemonic: mnemonic, keyPair: keyPair);

    // Re-register with server.
    try {
      final generation = await _identity.registerPublicKey(
        publicKeyHex: keyPair.publicKeyHex,
      );
      await _vault.writeKeyGeneration(generation);
    } catch (_) {
      // Will retry later.
    }

    return keyPair;
  }

  /// Checks if identity is already set up.
  Future<bool> hasIdentity() => _vault.hasIdentity();

  /// Returns the locally stored key pair, if available.
  Future<CryptoKeyPair?> getKeyPair() => _vault.readKeyPair();

  /// Whether the user has confirmed their mnemonic backup.
  Future<bool> isBackupConfirmed() => _vault.isBackupConfirmed();

  /// Marks the backup as confirmed.
  Future<void> confirmBackup() => _vault.confirmBackup();
}
