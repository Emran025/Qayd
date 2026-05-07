import 'package:qayd/application/sync/audit_sync_dispatcher.dart';
import 'package:qayd/domain/entities/device_session.dart';
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
  });

  final DeviceSessionRepository deviceSessionRepository;
  final DeviceRegistryRepository deviceRegistryRepository;
  final AuditLogRepository auditLogRepository;
  final AuditSyncDispatcher auditSyncDispatcher;
  final Future<CryptoKeyPair?> Function() getCurrentKeyPair;

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
}
