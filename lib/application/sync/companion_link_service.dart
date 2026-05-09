import 'package:flutter/foundation.dart';
import 'package:qayd/application/identity/setup_identity_use_case.dart';
import 'package:qayd/application/sync/credential_bootstrap_payload.dart';
import 'package:qayd/application/sync/device_pairing_qr_service.dart';
import 'package:qayd/core/constants/api_endpoints.dart';
import 'package:qayd/data/network/api_client.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/data/security/mnemonic_vault.dart';
import 'package:qayd/domain/repositories/device_registry_repository.dart';
import 'package:qayd/domain/services/e2ee_encryption_service.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';
import 'package:qayd/domain/services/crypto_identity_service.dart';
import 'package:uuid/uuid.dart';

class CompanionLinkSession {
  const CompanionLinkSession({
    required this.qrPayload,
    required this.socketSessionId,
    required this.ephemeralKeyPair,
    required this.nonce,
  });

  final String qrPayload;
  final String socketSessionId;
  final CryptoKeyPair ephemeralKeyPair;
  final String nonce;
}

class CompanionLinkService {
  CompanionLinkService({
    required this.qrService,
    required this.e2eeService,
    required this.apiClient,
    required this.mnemonicVault,
    required this.licenseVault,
    required this.setupIdentityUseCase,
    required this.getCurrentKeyPair,
    required this.cryptoIdentityService,
    required this.deviceRegistryRepository,
    required this.getCurrentDeviceId,
  });

  final DevicePairingQrService qrService;
  final E2EEEncryptionService e2eeService;
  final ApiClient apiClient;
  final MnemonicVault mnemonicVault;
  final LicenseVault licenseVault;
  final SetupIdentityUseCase setupIdentityUseCase;
  final Future<CryptoKeyPair?> Function() getCurrentKeyPair;
  final CryptoIdentityService cryptoIdentityService;
  final DeviceRegistryRepository deviceRegistryRepository;
  final Future<String> Function() getCurrentDeviceId;

  final Set<String> _usedNonces = <String>{};

  CompanionLinkSession startReceiverSession() {
    // Clear nonces from previous sessions to prevent unbounded accumulation.
    // Each QR has its own nonce, so old ones are irrelevant after the session expires.
    _usedNonces.clear();

    final ephemeral = _generateEphemeralKeyPair();
    final sessionId = const Uuid().v4();
    final qr = qrService.generateCompanionLinkQr(
      ephemeralPublicKeyHex: ephemeral.publicKeyHex,
      socketSessionId: sessionId,
    );
    final decoded = qrService.parseCompanionLinkQr(qr)!;
    return CompanionLinkSession(
      qrPayload: qr,
      socketSessionId: sessionId,
      ephemeralKeyPair: ephemeral,
      nonce: decoded.nonce,
    );
  }

  Future<void> sendBootstrapToCompanion({required String scannedQr}) async {
    final parsed = qrService.parseCompanionLinkQr(scannedQr);
    if (parsed == null) {
      throw StateError('Invalid companion QR payload.');
    }
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(minutes: 30));
    final mnemonic = await mnemonicVault.readMnemonic();
    final jwt = await licenseVault.readJwt();
    final senderPair = await getCurrentKeyPair();
    if (mnemonic == null || jwt == null || jwt.isEmpty || senderPair == null) {
      throw StateError('Missing secure credentials for bootstrap.');
    }
    final payload = CredentialBootstrapPayload(
      version: 1,
      nonce: parsed.nonce,
      mnemonic: mnemonic.phrase,
      jwt: jwt,
      issuedAtIso: now.toIso8601String(),
      expiresAtIso: expiresAt.toIso8601String(),
      licenseData: await licenseVault.readLicenseData(),
    );

    final encrypted = await e2eeService.encryptPayload(
      rawPayload: payload.toMap(),
      senderKeyPair: senderPair,
      receiverPublicKeyHex: parsed.ephemeralPublicKeyHex,
    );
    await apiClient.post(
      ApiEndpoints.devicesCompanionBootstrap,
      body: {
        'socket_session_id': parsed.socketSessionId,
        'encrypted_payload': encrypted,
        'nonce': parsed.nonce,
        'expires_at': expiresAt.toIso8601String(),
      },
    );
  }

  Future<bool> pollAndConsumeBootstrap({
    required CompanionLinkSession session,
  }) async {
    Map<String, dynamic>? res;
    try {
      res = await apiClient.post(
        ApiEndpoints.devicesCompanionConsume,
        body: {'socket_session_id': session.socketSessionId},
      ) as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('CompanionLink: poll request failed: $e');
      return false;
    }

    if (res == null) return false;
    final encrypted = res['encrypted_payload'] as String?;
    final senderPublicKey = res['sender_public_key'] as String?;
    if (encrypted == null || senderPublicKey == null) {
      debugPrint('CompanionLink: no bootstrap payload available yet.');
      return false;
    }

    Map<String, dynamic> payload;
    try {
      payload = await e2eeService.decryptPayload(
        encryptedPayload: encrypted,
        receiverKeyPair: session.ephemeralKeyPair,
        senderPublicKeyHex: senderPublicKey,
      );
    } catch (e) {
      debugPrint('CompanionLink: decryption failed: $e');
      return false;
    }

    final model = CredentialBootstrapPayload.fromMap(payload);
    if (!_validateNonceAndFreshness(model, session.nonce)) {
      debugPrint('CompanionLink: nonce/freshness check failed — stale bootstrap.');
      return false;
    }

    // §C-1: Persist mnemonic + JWT for data access, then generate a NEW
    // unique keypair for this companion device's own identity.
    final companionKeyPair = await _persistBootstrap(model);

    // §C-4: Register the companion's unique device key on the server.
    // NOTE: ensureServerRegistration() must NOT run on companion devices
    // as it would re-register the mnemonic-derived key (= Primary's key)
    // and overwrite the Primary's identity on the server.
    // We explicitly mark server-key as 'registered' so ensureServerRegistration
    // considers its job done, even though the companion never calls identity/register-key.
    // The companion's unique key lives ONLY in user_devices, not in users.public_key.
    await mnemonicVault.markServerKeyRegistered();

    await _registerCompanionDeviceWithOwnKey(companionKeyPair);
    return true;
  }

  /// Persists the bootstrap credentials and sets up the mnemonic identity
  /// for data access. Returns a **new companion-specific keypair**.
  ///
  /// §C-1 Security Note:
  /// The mnemonic received from Primary is used to restore data access
  /// (voucher decryption keys), but the companion generates its OWN
  /// Ed25519 keypair for device authentication and sync routing.
  /// This prevents the identity mismatch where both devices fight over
  /// the same public key on the server.
  Future<CryptoKeyPair> _persistBootstrap(
      CredentialBootstrapPayload payload) async {
    await licenseVault.writeJwt(payload.jwt);
    await licenseVault.setIsCompanionDevice(true);
    if (payload.licenseData != null) {
      await licenseVault.writeLicenseData(payload.licenseData!);
    }

    // Restore mnemonic for data-layer key derivation (voucher encryption).
    // primaryLicenseData is passed so recoverFromMnemonic skips server
    // re-registration of the Primary's key under our identity.
    await setupIdentityUseCase.recoverFromMnemonic(
      MnemonicPhrase.fromPhrase(payload.mnemonic),
      primaryLicenseData: payload.licenseData,
    );

    // §C-1: Generate a unique keypair for this companion device.
    // This is entirely separate from the mnemonic-derived Primary key.
    final companionKeyPair = _generateEphemeralKeyPair();
    await mnemonicVault.writeKeyPair(companionKeyPair);
    debugPrint(
      'CompanionLink: companion device key generated: '
      '${companionKeyPair.publicKeyHex.substring(0, 8)}…',
    );
    return companionKeyPair;
  }

  /// Registers the companion's OWN unique keypair with the server.
  /// This is distinct from the Primary's keypair stored in license_data.
  ///
  /// §C-4: We ONLY register with devices/pair — never with identity/register-key.
  /// The companion's unique key lives in user_devices.public_key only.
  /// The account's users.public_key remains the Primary's key, untouched.
  Future<void> _registerCompanionDeviceWithOwnKey(
      CryptoKeyPair companionKeyPair) async {
    final publicKeyHex = companionKeyPair.publicKeyHex.toLowerCase();
    final deviceId = await getCurrentDeviceId();
    final signedChallenge =
        'companion-bootstrap:$deviceId:${DateTime.now().millisecondsSinceEpoch}';
    try {
      await deviceRegistryRepository.pairDevice(
        deviceId: deviceId,
        deviceName: 'Companion Device',
        publicKeyHex: publicKeyHex,
        signedChallenge: signedChallenge,
      );
      debugPrint(
        'CompanionLink: companion registered on server '
        '[key: ${publicKeyHex.substring(0, 8)}…, device: $deviceId]',
      );
    } catch (e) {
      // Non-fatal — credentials are already persisted.
      // The device will re-register on next app start via the normal device refresh.
      debugPrint('CompanionLink: server device registration deferred: $e');
    }
  }

  bool _validateNonceAndFreshness(
      CredentialBootstrapPayload payload, String expectedNonce) {
    if (payload.nonce.isEmpty || payload.nonce != expectedNonce) return false;
    if (_usedNonces.contains(payload.nonce)) return false;
    _usedNonces.add(payload.nonce);
    final issuedAt = DateTime.tryParse(payload.issuedAtIso);
    final expiresAt = DateTime.tryParse(payload.expiresAtIso);
    final now = DateTime.now().toUtc();
    if (issuedAt == null || expiresAt == null) return false;
    if (now.isAfter(expiresAt)) return false;
    if (issuedAt.isAfter(now.add(const Duration(minutes: 1)))) return false;
    return true;
  }

  CryptoKeyPair _generateEphemeralKeyPair() {
    final mnemonic = cryptoIdentityService.generateMnemonic();
    return cryptoIdentityService.deriveKeyPair(mnemonic);
  }
}
