import 'package:qayd/domain/entities/device_session.dart';

abstract interface class DeviceSessionRepository {
  Future<void> upsert(DeviceSession session);

  Future<List<DeviceSession>> listAll();

  Future<List<DeviceSession>> listActive();

  Future<DeviceSession?> getById(String deviceId);

  Future<void> setActive(String deviceId, bool isActive);

  Future<void> updateLastSyncSeq(String deviceId, int lastSyncSeq);

  Future<void> updateLastSeen(String deviceId, DateTime at);
}
