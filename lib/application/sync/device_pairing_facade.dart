import 'package:qayd/application/sync/device_pairing_service.dart';
import 'package:qayd/application/sync/manual_link_service.dart';
import 'package:qayd/domain/entities/device_session.dart';
import 'package:qayd/domain/repositories/device_session_repository.dart';

class DevicePairingFacade {
  DevicePairingFacade({
    required DevicePairingService pairingService,
    required DeviceSessionRepository sessionRepository,
    required ManualLinkService manualLinkService,
  })  : _pairingService = pairingService,
        _sessionRepository = sessionRepository,
        _manualLinkService = manualLinkService;

  final DevicePairingService _pairingService;
  final DeviceSessionRepository _sessionRepository;
  final ManualLinkService _manualLinkService;

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

  Future<void> sendCompanionBootstrap({
    required String scannedQr,
    required Future<bool> Function() approvalGate,
  }) {
    return _pairingService.sendCompanionBootstrap(
      scannedQr: scannedQr,
      approvalGate: approvalGate,
    );
  }

  /// PRIMARY DEVICE: Request a new 8-character short code from the server.
  Future<ManualLinkCodeResult> generateManualLinkCode() {
    return _manualLinkService.generateShortCode();
  }

  /// PRIMARY DEVICE: Send bootstrap to companion identified via manual code.
  /// The pairing service polls internally until the Companion enters the code.
  Future<void> sendBootstrapViaCode({
    required String shortCode,
    required Future<bool> Function() approvalGate,
  }) {
    return _pairingService.sendCompanionBootstrapViaCode(
      shortCode: shortCode,
      manualLinkService: _manualLinkService,
      approvalGate: approvalGate,
    );
  }

  /// COMPANION DEVICE: Submit ephemeral keys via short code entered by user.
  Future<ManualLinkSession> submitViaManualCode({
    required String shortCode,
  }) async {
    final session = await _pairingService.companionLinkService.submitViaManualCode(
      shortCode: shortCode,
      manualLinkService: _manualLinkService,
    );
    // Convert CompanionLinkSession to a ManualLinkSession that carries the
    // polling data needed for the UI to wait for the bootstrap.
    return ManualLinkSession(companionSession: session);
  }

  Future<List<DeviceSession>> revokeDevice(String deviceId) async {
    await _pairingService.revokeDevice(deviceId);
    return _sessionRepository.listAll();
  }
}

/// Thin wrapper returned to the Companion UI from [submitViaManualCode].
/// Carries the session needed to continue polling for the bootstrap payload.
class ManualLinkSession {
  const ManualLinkSession({required this.companionSession});
  final dynamic companionSession; // CompanionLinkSession
}
