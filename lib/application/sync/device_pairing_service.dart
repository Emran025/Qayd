import 'package:qayd/application/sync/audit_sync_dispatcher.dart';
import 'package:qayd/domain/entities/device_session.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:qayd/domain/repositories/device_session_repository.dart';

class DevicePairingService {
  DevicePairingService({
    required this.deviceSessionRepository,
    required this.auditLogRepository,
    required this.auditSyncDispatcher,
  });

  final DeviceSessionRepository deviceSessionRepository;
  final AuditLogRepository auditLogRepository;
  final AuditSyncDispatcher auditSyncDispatcher;

  Future<void> pairDevice({
    required String deviceId,
    required String deviceName,
    required String publicKeyHex,
    required bool isCurrent,
  }) async {
    await deviceSessionRepository.upsert(
      DeviceSession(
        deviceId: deviceId,
        deviceName: deviceName,
        publicKeyHex: publicKeyHex,
        pairedAt: DateTime.now(),
        lastSyncSeq: 0,
        isCurrent: isCurrent,
        isActive: true,
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
}
