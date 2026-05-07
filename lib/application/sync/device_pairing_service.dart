import 'dart:convert';

import 'package:qayd/application/sync/audit_sync_dispatcher.dart';
import 'package:qayd/application/sync/device_pairing_qr_service.dart';
import 'package:qayd/domain/entities/device_session.dart';
import 'package:qayd/domain/services/crypto_identity_service.dart';
import 'package:qayd/domain/services/receipt_signing_service.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:qayd/domain/repositories/device_registry_repository.dart';
import 'package:qayd/domain/repositories/device_session_repository.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';

class DevicePairingService {
  DevicePairingService({
    required this.deviceSessionRepository,
    required this.deviceRegistryRepository,
    required this.auditLogRepository,
    required this.auditSyncDispatcher,
    required this.getCurrentKeyPair,
    required this.getCurrentDeviceId,
    required this.qrService,
    required this.signingService,
    required this.cryptoService,
  });

  final DeviceSessionRepository deviceSessionRepository;
  final DeviceRegistryRepository deviceRegistryRepository;
  final AuditLogRepository auditLogRepository;
  final AuditSyncDispatcher auditSyncDispatcher;
  final Future<CryptoKeyPair?> Function() getCurrentKeyPair;
  final Future<String> Function() getCurrentDeviceId;
  final DevicePairingQrService qrService;
  final ReceiptSigningService signingService;
  final CryptoIdentityService cryptoService;

  Future<void> pairDevice({
    required String deviceId,
    required String deviceName,
    required String publicKeyHex,
    required bool isCurrent,
  }) async {
    final signedChallenge = await _buildSignedChallenge(
      deviceId: deviceId,
      publicKeyHex: publicKeyHex,
    );
    final serverSession = await deviceRegistryRepository.pairDevice(
      deviceId: deviceId,
      deviceName: deviceName,
      publicKeyHex: publicKeyHex,
      signedChallenge: signedChallenge,
    );
    await deviceSessionRepository.upsert(
      DeviceSession(
        deviceId: serverSession.deviceId,
        deviceName: serverSession.deviceName,
        publicKeyHex: serverSession.publicKeyHex,
        pairedAt: serverSession.pairedAt,
        lastSyncSeq: serverSession.lastSyncSeq,
        lastSeenAt: serverSession.lastSeenAt,
        isCurrent: isCurrent,
        isActive: serverSession.isActive,
      ),
    );
  }

  Future<void> dispatchInitialSnapshot(String targetDeviceId) async {
    final session = await deviceSessionRepository.getById(targetDeviceId);
    if (session == null || !session.isActive) return;
    final all = await auditLogRepository.listAll();
    for (final entry in all.reversed) {
      await auditSyncDispatcher.dispatchEntryToDevice(
        entry: entry,
        targetDeviceId: targetDeviceId,
        receiverPublicKeyHex: session.publicKeyHex,
      );
    }
  }

  Future<String?> buildMyPairingQr({required String deviceName}) async {
    final pair = await getCurrentKeyPair();
    if (pair == null) return null;
    final deviceId = await getCurrentDeviceId();
    return qrService.generateQr(
      deviceId: deviceId,
      publicKeyHex: pair.publicKeyHex,
      deviceName: deviceName,
    );
  }

  Future<void> pairFromQr({
    required String scannedQr,
    required String localDeviceName,
  }) async {
    final remote = qrService.parseQr(scannedQr);
    final pair = await getCurrentKeyPair();
    if (remote == null || pair == null) {
      throw StateError('Invalid pairing QR payload.');
    }

    final localDeviceId = await getCurrentDeviceId();
    final signedChallenge = _signChallenge(
      challenge: remote.pairingChallenge,
      remoteDeviceId: remote.deviceId,
      localDeviceId: localDeviceId,
      localPublicKeyHex: pair.publicKeyHex,
      keyPair: pair,
    );

    // Register this local device against the account after QR challenge signing.
    await deviceRegistryRepository.pairDevice(
      deviceId: localDeviceId,
      deviceName: localDeviceName,
      publicKeyHex: pair.publicKeyHex,
      signedChallenge: signedChallenge,
    );

    // Persist the remote paired device from QR as sync target.
    await deviceSessionRepository.upsert(
      DeviceSession(
        deviceId: remote.deviceId,
        deviceName: remote.deviceName,
        publicKeyHex: remote.publicKeyHex,
        pairedAt: DateTime.now(),
        lastSyncSeq: 0,
        isCurrent: false,
        isActive: true,
      ),
    );
  }

  Future<void> refreshSessionsFromServer() async {
    final sessions = await deviceRegistryRepository.listDevices();
    for (final session in sessions) {
      await deviceSessionRepository.upsert(session);
    }
  }

  Future<void> revokeDevice(String deviceId) async {
    await deviceRegistryRepository.revokeDevice(deviceId);
    await deviceSessionRepository.setActive(deviceId, false);
  }

  Future<String> _buildSignedChallenge({
    required String deviceId,
    required String publicKeyHex,
  }) async {
    final pair = await getCurrentKeyPair();
    final nonce = DateTime.now().millisecondsSinceEpoch;
    final signer = pair?.publicKeyHex ?? 'unsigned';
    return '$signer:$deviceId:$publicKeyHex:$nonce';
  }

  String _signChallenge({
    required String challenge,
    required String remoteDeviceId,
    required String localDeviceId,
    required String localPublicKeyHex,
    required CryptoKeyPair keyPair,
  }) {
    final canonical = jsonEncode({
      'challenge': challenge,
      'remote_device_id': remoteDeviceId,
      'local_device_id': localDeviceId,
      'local_public_key': localPublicKeyHex,
    });
    final payloadHash = signingService.hashPayload(canonical);
    final signature = cryptoService.sign(payloadHash, keyPair);
    return base64Encode(signature.signatureBytes);
  }
}
