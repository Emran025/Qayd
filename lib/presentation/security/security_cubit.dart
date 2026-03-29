import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:qayd/data/security/app_pin_storage.dart';
import 'package:qayd/presentation/security/security_state.dart';

/// App lock: PIN + optional biometrics; locks after [lockAfterBackground] in background.
class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit({
    required AppPinStorage pinStorage,
    LocalAuthentication? localAuth,
    Duration lockAfterBackground = const Duration(minutes: 5),
  })  : _pinStorage = pinStorage,
        _localAuth = localAuth ?? LocalAuthentication(),
        _lockAfterBackground = lockAfterBackground,
        super(const SecurityUnlocked());

  final AppPinStorage _pinStorage;
  final LocalAuthentication _localAuth;
  final Duration _lockAfterBackground;

  DateTime? _pausedAt;

  Future<void> refreshPreferences() async {
    final lockOn = await _pinStorage.isLockEnabled();
    final hasPin = await _pinStorage.hasPinConfigured();
    if (!lockOn || !hasPin) {
      emit(const SecurityUnlocked());
    }
  }

  void onAppLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _maybeLockOnResume();
    }
  }

  Future<void> _maybeLockOnResume() async {
    final enabled = await _pinStorage.isLockEnabled();
    final hasPin = await _pinStorage.hasPinConfigured();
    if (!enabled || !hasPin) return;
    final t = _pausedAt;
    if (t == null) return;
    if (DateTime.now().difference(t) >= _lockAfterBackground) {
      emit(const SecurityLocked());
    }
    _pausedAt = null;
  }

  Future<void> unlockWithPin(String pin) async {
    final ok = await _pinStorage.verifyPin(pin);
    if (ok) {
      emit(const SecurityUnlocked());
    }
  }

  Future<bool> unlockWithBiometric({required String localizedReason}) async {
    final enabled = await _pinStorage.isBiometricEnabled();
    if (!enabled) return false;
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      final ok = await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        emit(const SecurityUnlocked());
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> canUseBiometric() async {
    if (!await _pinStorage.isBiometricEnabled()) return false;
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveNewPin(String pin) async {
    await _pinStorage.setPin(pin);
    await _pinStorage.setLockEnabled(true);
    await refreshPreferences();
  }

  Future<void> setLockEnabled(bool enabled) async {
    if (enabled && !await _pinStorage.hasPinConfigured()) {
      return;
    }
    await _pinStorage.setLockEnabled(enabled);
    await refreshPreferences();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _pinStorage.setBiometricEnabled(enabled);
    await refreshPreferences();
  }

  Future<bool> hasPinConfigured() => _pinStorage.hasPinConfigured();

  Future<bool> isLockEnabled() => _pinStorage.isLockEnabled();

  Future<bool> isBiometricEnabled() => _pinStorage.isBiometricEnabled();
}
