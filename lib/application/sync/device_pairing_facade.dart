import 'package:qayd/application/sync/device_pairing_service.dart';
import 'package:qayd/domain/entities/device_session.dart';
import 'package:qayd/domain/repositories/device_session_repository.dart';

class DevicePairingFacade {
  DevicePairingFacade({
    required DevicePairingService pairingService,
    required DeviceSessionRepository sessionRepository,
  })  : _pairingService = pairingService,
        _sessionRepository = sessionRepository;

  final DevicePairingService _pairingService;
  final DeviceSessionRepository _sessionRepository;

  Future<List<DeviceSession>> loadSessions() async {
    await _pairingService.refreshSessionsFromServer();
    return _sessionRepository.listAll();
  }

  Future<List<DeviceSession>> pairDevice({
    required String deviceId,
    required String deviceName,
    required String publicKeyHex,
    required bool isCurrent,
  }) async {
    await _pairingService.pairDevice(
      deviceId: deviceId,
      deviceName: deviceName,
      publicKeyHex: publicKeyHex,
      isCurrent: isCurrent,
    );
    await _pairingService.dispatchInitialSnapshot(deviceId);
    return _sessionRepository.listAll();
  }

  Future<String?> buildMyPairingQr({required String deviceName}) {
    return _pairingService.buildMyPairingQr(deviceName: deviceName);
  }

  Future<List<DeviceSession>> pairFromQr({
    required String scannedQr,
    required String localDeviceName,
  }) async {
    await _pairingService.pairFromQr(
      scannedQr: scannedQr,
      localDeviceName: localDeviceName,
    );
    return _sessionRepository.listAll();
  }

  Future<List<DeviceSession>> revokeDevice(String deviceId) async {
    await _pairingService.revokeDevice(deviceId);
    return _sessionRepository.listAll();
  }
}
