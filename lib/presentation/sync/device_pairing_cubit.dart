import 'package:flutter/foundation.dart';
import 'package:qayd/application/sync/device_pairing_service.dart';
import 'package:qayd/domain/entities/device_session.dart';
import 'package:qayd/domain/repositories/device_session_repository.dart';

class DevicePairingState {
  const DevicePairingState({
    this.sessions = const <DeviceSession>[],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.success,
  });

  final List<DeviceSession> sessions;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? success;

  DevicePairingState copyWith({
    List<DeviceSession>? sessions,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? success,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return DevicePairingState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      success: clearSuccess ? null : (success ?? this.success),
    );
  }
}

class DevicePairingCubit extends ChangeNotifier {
  DevicePairingCubit({
    required DeviceSessionRepository sessionRepository,
    required DevicePairingService pairingService,
  })  : _sessionRepository = sessionRepository,
        _pairingService = pairingService;

  final DeviceSessionRepository _sessionRepository;
  final DevicePairingService _pairingService;

  DevicePairingState _state = const DevicePairingState();
  DevicePairingState get state => _state;

  void _emit(DevicePairingState state) {
    _state = state;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      final sessions = await _sessionRepository.listAll();
      _emit(_state.copyWith(isLoading: false, sessions: sessions));
    } catch (_) {
      _emit(_state.copyWith(
        isLoading: false,
        error: 'Unable to load paired devices.',
      ));
    }
  }

  Future<void> pair({
    required String deviceId,
    required String deviceName,
    required String publicKeyHex,
  }) async {
    _emit(_state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    ));
    try {
      await _pairingService.pairDevice(
        deviceId: deviceId,
        deviceName: deviceName,
        publicKeyHex: publicKeyHex,
        isCurrent: false,
      );
      await _pairingService.dispatchInitialSnapshot(deviceId);
      final sessions = await _sessionRepository.listAll();
      _emit(_state.copyWith(
        isSaving: false,
        sessions: sessions,
        success: 'Device paired successfully.',
      ));
    } catch (_) {
      _emit(_state.copyWith(
        isSaving: false,
        error: 'Pairing failed.',
      ));
    }
  }

  Future<void> revoke(String deviceId) async {
    await _sessionRepository.setActive(deviceId, false);
    await load();
  }
}
