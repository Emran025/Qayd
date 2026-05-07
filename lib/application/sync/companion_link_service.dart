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
    final expiresAt = now.add(const Duration(minutes: 3));
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
    final res = await apiClient.post(
      ApiEndpoints.devicesCompanionConsume,
      body: {'socket_session_id': session.socketSessionId},
    );
    if (res is! Map<String, dynamic>) return false;
    final encrypted = res['encrypted_payload'] as String?;
    final senderPublicKey = res['sender_public_key'] as String?;
    if (encrypted == null || senderPublicKey == null) return false;

    final payload = await e2eeService.decryptPayload(
      encryptedPayload: encrypted,
      receiverKeyPair: session.ephemeralKeyPair,
      senderPublicKeyHex: senderPublicKey,
    );
    final model = CredentialBootstrapPayload.fromMap(payload);
    if (!_validateNonceAndFreshness(model, session.nonce)) return false;

    final keyPair = await _persistBootstrap(model);
    await _registerRecoveredCompanionIdentity(keyPair);
    return true;
  }

  Future<CryptoKeyPair> _persistBootstrap(
      CredentialBootstrapPayload payload) async {
    await licenseVault.writeJwt(payload.jwt);
    await licenseVault.setIsCompanionDevice(true);
    if (payload.licenseData != null) {
      await licenseVault.writeLicenseData(payload.licenseData!);
    }
    return setupIdentityUseCase.recoverFromMnemonic(
      MnemonicPhrase.fromPhrase(payload.mnemonic),
    );
  }

  Future<void> _registerRecoveredCompanionIdentity(CryptoKeyPair keyPair) async {
    final publicKeyHex = keyPair.publicKeyHex.toLowerCase();
    final deviceId = await getCurrentDeviceId();
    final signedChallenge =
        'companion-bootstrap:$deviceId:${DateTime.now().millisecondsSinceEpoch}';
    await deviceRegistryRepository.pairDevice(
      deviceId: deviceId,
      deviceName: 'Companion Device',
      publicKeyHex: publicKeyHex,
      signedChallenge: signedChallenge,
    );
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
