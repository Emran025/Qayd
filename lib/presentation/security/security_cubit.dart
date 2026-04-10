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
import 'package:qayd/application/identity/sync_identity_to_internal_accounts_use_case.dart';
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
    required SyncIdentityToInternalAccountsUseCase syncIdentityUseCase,
    LocalAuthentication? localAuth,
    Duration lockAfterBackground = const Duration(minutes: 5),
  })  : _pinStorage = pinStorage,
        _licenseVault = licenseVault,
        _hardwareIdService = hardwareIdService,
        _clockGuard = clockGuard,
        _panicWipeService = panicWipeService,
        _authRepository = authRepository,
        _syncIdentityUseCase = syncIdentityUseCase,
        _localAuth = localAuth ?? LocalAuthentication(),
        _lockAfterBackground = lockAfterBackground,
        super(
          const SecurityUnlocked(
            licenseStatus: LicenseStatus.booting,
            trialDaysRemaining: LicenseVault.trialDurationDays,
          ),
        );

  final AppPinStorage _pinStorage;
  final LicenseVault _licenseVault;
  final HardwareIdService _hardwareIdService;
  final MonotonicClockGuard _clockGuard;
  final PanicWipeService _panicWipeService;
  final AuthRepository _authRepository;
  final SyncIdentityToInternalAccountsUseCase _syncIdentityUseCase;
  final LocalAuthentication _localAuth;
  final Duration _lockAfterBackground;

  DateTime? _pausedAt;

  // ── Boot sequence ─────────────────────────────────────────────────────────

  /// Must be called once after construction, before rendering.
  Future<void> bootCheck() async {
    // 1. Clock tamper detection.
    final tampered = await _clockGuard.detectTamper();
    if (tampered) {
      final trialDays = await trialDaysRemaining();
      emit(_withClock(ClockStatus.tampered, trialDaysRemaining: trialDays));
      return;
    }

    // 2. License check.
    final licenseStatus = await _resolveLicenseStatus();
    final trialDays = await trialDaysRemaining();

    // 3. If FORCE_REVOKE — wipe immediately.
    if (licenseStatus == LicenseStatus.revoked) {
      await _panicWipeService.wipeAll();
      emit(
        _buildState(
          licenseStatus: LicenseStatus.revoked,
          clockStatus: ClockStatus.clean,
          trialDaysRemaining: trialDays,
        ),
      );
      return;
    }

    // 4. PIN lock on startup if enabled.
    final lockEnabled = await _pinStorage.isLockEnabled();
    final hasPin = await _pinStorage.hasPinConfigured();
    final shouldPinLock = lockEnabled && hasPin;

    // 5. Sync identity to internal accounts (Owner link)
    _syncIdentityUseCase.call().ignore();

    emit(
      shouldPinLock
          ? SecurityLocked(
              licenseStatus: licenseStatus,
              trialDaysRemaining: trialDays,
            )
          : SecurityUnlocked(
              licenseStatus: licenseStatus,
              trialDaysRemaining: trialDays,
            ),
    );
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
    if (_licenseVault.isTrialExpired(trialStart))
      return LicenseStatus.trialExpired;
    return LicenseStatus.trial;
  }

  // ── PIN preferences ───────────────────────────────────────────────────────

  Future<void> refreshPreferences() async {
    final lockOn = await _pinStorage.isLockEnabled();
    final hasPin = await _pinStorage.hasPinConfigured();
    final ls = state.licenseStatus;
    final cs = state.clockStatus;
    if (!lockOn || !hasPin) {
      emit(
        SecurityUnlocked(
          licenseStatus: ls,
          clockStatus: cs,
          trialDaysRemaining: state.trialDaysRemaining,
        ),
      );
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
      emit(
        SecurityLocked(
          licenseStatus: state.licenseStatus,
          clockStatus: state.clockStatus,
          trialDaysRemaining: state.trialDaysRemaining,
        ),
      );
    }
    _pausedAt = null;
  }

  // ── PIN unlock ────────────────────────────────────────────────────────────

  Future<void> unlockWithPin(String pin) async {
    final ok = await _pinStorage.verifyPin(pin);
    if (ok) {
      emit(
        SecurityUnlocked(
          licenseStatus: state.licenseStatus,
          clockStatus: state.clockStatus,
          trialDaysRemaining: state.trialDaysRemaining,
        ),
      );
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
        emit(
          SecurityUnlocked(
            licenseStatus: state.licenseStatus,
            clockStatus: state.clockStatus,
            trialDaysRemaining: state.trialDaysRemaining,
          ),
        );
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
      final emailVerifiedAt = result.licenseData['email_verified_at'];
      final emailUnverified = emailVerifiedAt == null;

      if (status.isEmpty || status == 'trial') {
        final trialStart = await _licenseVault.readTrialStart();
        if (trialStart == null) {
          await _licenseVault.writeTrialStart(DateTime.now().toUtc());
        }
      }

      if (!emailUnverified) {
        final licenseStatus = await _resolveLicenseStatus();
        final trialDays = await trialDaysRemaining();
        emit(
          SecurityUnlocked(
            licenseStatus: licenseStatus,
            trialDaysRemaining: trialDays,
          ),
        );
      }

      // Sync identity to internal accounts after successful provision
      _syncIdentityUseCase.call().ignore();

      return ProvisioningResult.success(emailUnverified: emailUnverified);
    } on AuthException catch (e) {
      return ProvisioningResult.failure(e.messageAr);
    } catch (_) {
      return ProvisioningResult.failure(
        'تعذر الاتصال بالخادم. تحقق من الاتصال.',
      );
    }
  }

  // ── Panic wipe ────────────────────────────────────────────────────────────

  Future<void> executePanicWipe() async {
    await _panicWipeService.wipeAll();
    emit(
      const SecurityUnlocked(
        licenseStatus: LicenseStatus.pending,
        trialDaysRemaining: LicenseVault.trialDurationDays,
      ),
    );
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

  SecurityState _withClock(ClockStatus cs, {int? trialDaysRemaining}) {
    return SecurityLocked(
      licenseStatus: state.licenseStatus,
      clockStatus: cs,
      trialDaysRemaining: trialDaysRemaining ?? state.trialDaysRemaining,
    );
  }

  SecurityState _buildState({
    required LicenseStatus licenseStatus,
    required ClockStatus clockStatus,
    int? trialDaysRemaining,
  }) {
    return SecurityUnlocked(
      licenseStatus: licenseStatus,
      clockStatus: clockStatus,
      trialDaysRemaining: trialDaysRemaining ?? state.trialDaysRemaining,
    );
  }
}

/// Result of a provisioning (API login) attempt.
final class ProvisioningResult {
  const ProvisioningResult._({
    required this.success,
    this.emailUnverified = false,
    this.errorAr,
  });

  factory ProvisioningResult.success({bool emailUnverified = false}) =>
      ProvisioningResult._(success: true, emailUnverified: emailUnverified);

  factory ProvisioningResult.failure(String messageAr) =>
      ProvisioningResult._(success: false, errorAr: messageAr);

  final bool success;
  final bool emailUnverified;
  final String? errorAr;
}
