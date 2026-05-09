import 'package:flutter/material.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/entities/party_details.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';
import 'package:qayd/data/security/identity_file_storage.dart';
import 'package:qayd/data/security/mnemonic_vault.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/services/crypto_identity_service.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:uuid/uuid.dart';
import 'package:qayd/core/result/result.dart';

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
    required AccountRepository Function() accountRepositoryProvider,
  })  : _crypto = cryptoService,
        _vault = mnemonicVault,
        _identity = identityRepository,
        _fileStorage = identityFileStorage,
        _accountRepositoryProvider = accountRepositoryProvider;

  final CryptoIdentityService _crypto;
  final MnemonicVault _vault;
  final IdentityRepository _identity;
  final IdentityFileStorage _fileStorage;
  final AccountRepository Function() _accountRepositoryProvider;

  AccountRepository get _accountRepository => _accountRepositoryProvider();

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
    await _vault.clearServerKeyRegistered();

    // Persist to file alongside the database for auto-restore after reinstall.
    await _fileStorage.persist(mnemonic: mnemonic, keyPair: keyPair);

    // Register public key with server.
    try {
      final generation = await _identity.registerPublicKey(
        publicKeyHex: keyPair.publicKeyHex,
      );
      await _vault.writeKeyGeneration(generation);
      await _vault.markServerKeyRegistered();
    } catch (_) {
      // Server registration failed — will be retried via ensureServerRegistration().
    }

    return mnemonic;
  }

  /// Recovers identity from a mnemonic phrase (device loss / migration).
  ///
  /// Derives the same key pair from the seed, re-registers with server,
  /// and refreshes the device identity file.
  Future<CryptoKeyPair> recoverFromMnemonic(
    MnemonicPhrase mnemonic, {
    Map<String, dynamic>? primaryLicenseData,
  }) async {
    final keyPair = _crypto.deriveKeyPair(mnemonic);

    await _vault.writeMnemonic(mnemonic);
    await _vault.writeKeyPair(keyPair);
    await _vault.clearServerKeyRegistered();

    // Refresh identity file after recovery.
    await _fileStorage.persist(mnemonic: mnemonic, keyPair: keyPair);

    // Re-register with server ONLY if we are NOT a companion device.
    // Registering a different key from a companion would hijack the master identity and break the primary.
    if (primaryLicenseData == null) {
      try {
        final generation = await _identity.registerPublicKey(
          publicKeyHex: keyPair.publicKeyHex,
        );
        await _vault.writeKeyGeneration(generation);
        await _vault.markServerKeyRegistered();
      } catch (_) {
        // Will be retried via ensureServerRegistration().
      }
    } else {
      // For companions: store the primary's generation number for reference.
      // Do NOT call markServerKeyRegistered() here — the companion will
      // overwrite the stored keypair with its own unique key immediately
      // after this call (in _persistBootstrap), and will register that key.
      final gen = (primaryLicenseData['key_generation'] as num?)?.toInt() ?? 1;
      await _vault.writeKeyGeneration(gen);

      // The mnemonic-derived key will intentionally differ from Primary's
      // registered key. This is expected and no longer a hard error.
      final serverPk = primaryLicenseData['public_key']?.toString() ?? '';
      if (serverPk.isNotEmpty &&
          serverPk.toLowerCase() != keyPair.publicKeyHex.toLowerCase()) {
        debugPrint(
          'Identity [companion]: Mnemonic-derived key differs from Primary key '
          '(${keyPair.publicKeyHex.substring(0, 8)}… vs ${serverPk.substring(0, 8)}…). '
          'Companion will use its own unique key \u2014 this is expected.',
        );
      }
    }
    return keyPair;
  }

  Future<void> trustPrimaryIdentity(Map<String, dynamic> licenseData) async {
    final pk = licenseData['public_key'] as String?;
    final phone = licenseData['phone'] as String?;
    final name = licenseData['name'] as String? ?? 'Primary Device';
    final email = licenseData['email'] as String?;
    final serverId = (licenseData['id'] as num?)?.toInt();

    if (pk == null || pk.isEmpty) return;
    final normalizedPk = pk.toLowerCase();

    // Check if we already have a primary device account entry.
    // We update it even if it exists, because the Primary's public key
    // may have been rotated since the last linking session.
    final existingByKey =
        await _accountRepository.findAccountByPublicKey(normalizedPk);
    if (existingByKey.isSuccess && existingByKey.valueOrNull != null) {
      // Already known with this exact key — nothing to do.
      debugPrint('Identity: Primary key already trusted: ${normalizedPk.substring(0, 8)}…');
      return;
    }

    // Check if a primary device entry exists with a DIFFERENT (old) key.
    // If so, update its public key to the new one from the bootstrap.
    if (phone != null && phone.isNotEmpty) {
      final existingByPhone =
          await _accountRepository.findAccountByPhone(phone);
      if (existingByPhone.isSuccess && existingByPhone.valueOrNull != null) {
        final existingId = existingByPhone.valueOrNull!;
        final oldDetails = await _accountRepository.getPartyDetails(existingId);
        if (oldDetails.isSuccess && oldDetails.valueOrNull != null) {
          final updatedDetails = oldDetails.valueOrNull!.copyWith(
            currentPublicKeyHex: normalizedPk,
            serverAccountId: serverId ?? oldDetails.valueOrNull!.serverAccountId,
            email: email ?? oldDetails.valueOrNull!.email,
          );
          await _accountRepository.savePartyDetails(updatedDetails);
          debugPrint(
            'Identity: Updated Primary key to ${normalizedPk.substring(0, 8)}… '
            '(was ${(oldDetails.valueOrNull!.currentPublicKeyHex ?? '?').substring(0, 8)}…)',
          );
          return;
        }
      }
    }

    // Create a new trusted account for the primary identity.
    final accountId = AccountId(const Uuid().v4());
    final account = Account.createRoot(
      id: accountId,
      name: name,
      classification: AccountClassification.receivables,
      createdAt: DateTime.now(),
      metadata: {'is_primary_device': true},
    );

    await _accountRepository.save(account);

    final details = PartyDetails(
      accountId: accountId,
      phoneNumber: phone,
      email: email,
      currentPublicKeyHex: normalizedPk,
      serverAccountId: serverId,
      partyType: 'Primary',
    );

    await _accountRepository.savePartyDetails(details);
    debugPrint(
      'Identity: Registered Primary as trusted peer: '
      '${normalizedPk.substring(0, 8)}… (phone: $phone)',
    );
  }

  /// Retries server registration if a previous attempt failed.
  ///
  /// Safe to call on every boot — exits immediately if already registered.
  /// Returns `true` if the registration is now confirmed.
  Future<bool> ensureServerRegistration() async {
    if (await _vault.isServerKeyRegistered()) return true;

    final keyPair = await _vault.readKeyPair();
    if (keyPair == null) return false; // No identity to register.

    try {
      final generation = await _identity.registerPublicKey(
        publicKeyHex: keyPair.publicKeyHex,
      );
      await _vault.writeKeyGeneration(generation);
      await _vault.markServerKeyRegistered();
      return true;
    } catch (_) {
      return false;
    }
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
