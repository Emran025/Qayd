import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/data/security/app_pin_storage.dart';
import 'package:qayd/data/security/hardware_id_service.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/data/security/monotonic_clock_guard.dart';
import 'package:qayd/data/security/panic_wipe_service.dart';
import 'package:qayd/domain/repositories/auth_repository.dart';
import 'package:qayd/presentation/security/security_state.dart';

/// Unified security cubit.
///
/// Responsibilities (Phase 7):
///   1. PIN / biometric lock (existing).
///   2. License status: pending → trial → active | trialExpired | revoked | deviceUnbound.
///   3. Monotonic clock tamper detection.
///   4. Panic wipe on FORCE_REVOKE.
class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit({
    required AppPinStorage pinStorage,
    required LicenseVault licenseVault,
    required HardwareIdService hardwareIdService,
    required MonotonicClockGuard clockGuard,
    required PanicWipeService panicWipeService,
    required AuthRepository authRepository,
    LocalAuthentication? localAuth,
    Duration lockAfterBackground = const Duration(minutes: 5),
  })  : _pinStorage = pinStorage,
        _licenseVault = licenseVault,
        _hardwareIdService = hardwareIdService,
        _clockGuard = clockGuard,
        _panicWipeService = panicWipeService,
        _authRepository = authRepository,
        _localAuth = localAuth ?? LocalAuthentication(),
        _lockAfterBackground = lockAfterBackground,
        super(const SecurityUnlocked(licenseStatus: LicenseStatus.pending));

  final AppPinStorage _pinStorage;
  final LicenseVault _licenseVault;
  final HardwareIdService _hardwareIdService;
  final MonotonicClockGuard _clockGuard;
  final PanicWipeService _panicWipeService;
  final AuthRepository _authRepository;
  final LocalAuthentication _localAuth;
  final Duration _lockAfterBackground;

  DateTime? _pausedAt;

  // ── Boot sequence ─────────────────────────────────────────────────────────

  /// Must be called once after construction, before rendering.
  Future<void> bootCheck() async {
    // 1. Clock tamper detection.
    final tampered = await _clockGuard.detectTamper();
    if (tampered) {
      emit(_withClock(ClockStatus.tampered));
      return;
    }

    // 2. License check.
    final licenseStatus = await _resolveLicenseStatus();

    // 3. If FORCE_REVOKE — wipe immediately.
    if (licenseStatus == LicenseStatus.revoked) {
      await _panicWipeService.wipeAll();
      emit(_buildState(
        licenseStatus: LicenseStatus.revoked,
        clockStatus: ClockStatus.clean,
      ));
      return;
    }

    // 4. PIN lock on startup if enabled.
    final lockEnabled = await _pinStorage.isLockEnabled();
    final hasPin = await _pinStorage.hasPinConfigured();
    final shouldPinLock = lockEnabled && hasPin;

    emit(shouldPinLock
        ? SecurityLocked(licenseStatus: licenseStatus)
        : SecurityUnlocked(licenseStatus: licenseStatus));
  }

  Future<LicenseStatus> _resolveLicenseStatus() async {
    final provisioned = await _licenseVault.isProvisioned();
    if (!provisioned) return LicenseStatus.pending;

    // Verify hardware binding.
    final currentHwId = await _hardwareIdService.obtainHardwareId();
    final boundHwId = await _licenseVault.readProvisionedHardwareId();
    if (boundHwId != null && boundHwId.isNotEmpty && boundHwId != currentHwId) {
      return LicenseStatus.deviceUnbound;
    }

    // Read license data.
    final data = await _licenseVault.readLicenseData();
    if (data != null) {
      final status = data['status'] as String? ?? '';
      if (status == 'FORCE_REVOKE' || status == 'revoked') {
        return LicenseStatus.revoked;
      }
      if (status == 'active') return LicenseStatus.active;
      if (status == 'suspended') return LicenseStatus.suspended;
    }

    // Fall back to trial clock.
    final trialStart = await _licenseVault.readTrialStart();
    if (trialStart == null) {
      await _licenseVault.writeTrialStart(DateTime.now().toUtc());
      return LicenseStatus.trial;
    }
    if (_licenseVault.isTrialExpired(trialStart)) return LicenseStatus.trialExpired;
    return LicenseStatus.trial;
  }

  // ── PIN preferences ───────────────────────────────────────────────────────

  Future<void> refreshPreferences() async {
    final lockOn = await _pinStorage.isLockEnabled();
    final hasPin = await _pinStorage.hasPinConfigured();
    final ls = state.licenseStatus;
    final cs = state.clockStatus;
    if (!lockOn || !hasPin) {
      emit(SecurityUnlocked(licenseStatus: ls, clockStatus: cs));
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void onAppLifecycle(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      // Stamp the monotonic clock every time we background.
      _clockGuard.stamp();
      return;
    }
    if (lifecycle == AppLifecycleState.resumed) {
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
      emit(SecurityLocked(
        licenseStatus: state.licenseStatus,
        clockStatus: state.clockStatus,
      ));
    }
    _pausedAt = null;
  }

  // ── PIN unlock ────────────────────────────────────────────────────────────

  Future<void> unlockWithPin(String pin) async {
    final ok = await _pinStorage.verifyPin(pin);
    if (ok) {
      emit(SecurityUnlocked(
        licenseStatus: state.licenseStatus,
        clockStatus: state.clockStatus,
      ));
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
        emit(SecurityUnlocked(
          licenseStatus: state.licenseStatus,
          clockStatus: state.clockStatus,
        ));
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

  // ── API provisioning ──────────────────────────────────────────────────────

  /// Login to governance API and store credentials.
  Future<ProvisioningResult> provisionDevice({
    required String email,
    required String password,
  }) async {
    try {
      final hardwareId = await _hardwareIdService.obtainHardwareId();

      final result = await _authRepository.login(
        email: email,
        password: password,
        deviceId: hardwareId,
      );

      await _licenseVault.writeJwt(result.jwt);
      await _licenseVault.writeLicenseData(result.licenseData);
      await _licenseVault.writeProvisionedHardwareId(hardwareId);
      if (result.serverSalt.isNotEmpty) {
        await _licenseVault.writeServerSalt(result.serverSalt);
      }

      // Start trial clock if no license status found.
      final status = result.licenseData['status'] as String? ?? '';
      if (status.isEmpty || status == 'trial') {
        final trialStart = await _licenseVault.readTrialStart();
        if (trialStart == null) {
          await _licenseVault.writeTrialStart(DateTime.now().toUtc());
        }
      }

      final licenseStatus = await _resolveLicenseStatus();
      emit(SecurityUnlocked(licenseStatus: licenseStatus));
      return ProvisioningResult.success();
    } on AuthException catch (e) {
      return ProvisioningResult.failure(e.messageAr);
    } catch (_) {
      return ProvisioningResult.failure('تعذر الاتصال بالخادم. تحقق من الاتصال.');
    }
  }

  // ── Panic wipe ────────────────────────────────────────────────────────────

  Future<void> executePanicWipe() async {
    await _panicWipeService.wipeAll();
    emit(const SecurityUnlocked(licenseStatus: LicenseStatus.pending));
  }

  // ── PIN management ────────────────────────────────────────────────────────

  Future<void> saveNewPin(String pin) async {
    await _pinStorage.setPin(pin);
    await _pinStorage.setLockEnabled(true);
    await refreshPreferences();
  }

  Future<void> setLockEnabled(bool enabled) async {
    if (enabled && !await _pinStorage.hasPinConfigured()) return;
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

  // ── Trial info ────────────────────────────────────────────────────────────

  Future<int> trialDaysRemaining() async {
    final start = await _licenseVault.readTrialStart();
    if (start == null) return LicenseVault.trialDurationDays;
    return _licenseVault.daysRemainingInTrial(start);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  SecurityState _withClock(ClockStatus cs) => SecurityLocked(
        licenseStatus: state.licenseStatus,
        clockStatus: cs,
      );

  SecurityState _buildState({
    required LicenseStatus licenseStatus,
    required ClockStatus clockStatus,
  }) {
    return SecurityUnlocked(
      licenseStatus: licenseStatus,
      clockStatus: clockStatus,
    );
  }
}

/// Result of a provisioning (API login) attempt.
final class ProvisioningResult {
  const ProvisioningResult._({required this.success, this.errorAr});

  factory ProvisioningResult.success() =>
      const ProvisioningResult._(success: true);

  factory ProvisioningResult.failure(String messageAr) =>
      ProvisioningResult._(success: false, errorAr: messageAr);

  final bool success;
  final String? errorAr;
}
