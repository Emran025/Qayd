import 'package:qayd/domain/entities/device_session.dart';

abstract interface class DeviceRegistryRepository {
  Future<DeviceSession> pairDevice({
    required String deviceId,
    required String deviceName,
    required String publicKeyHex,
    required String signedChallenge,
  });

  Future<List<DeviceSession>> listDevices();

  Future<void> revokeDevice(String deviceId);
}
