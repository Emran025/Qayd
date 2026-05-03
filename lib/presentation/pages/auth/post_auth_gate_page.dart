import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/backup/restore_discovery_page.dart';
import 'package:qayd/presentation/pages/identity/seed_recovery_page.dart';
import 'package:qayd/presentation/pages/identity/seed_setup_page.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// The setup phases after authentication.
enum _GatePhase {
  /// Evaluating what the user needs.
  checking,

  /// Layer 2: Show backup restore options (for returning accounts).
  backupRestore,

  /// Layer 2: No backup — identity recovery or generation prompt.
  identityDecision,

  /// Layer 2: Auto-navigated to SeedSetupPage (new identity).
  identitySetup,

  /// Layer 3: Device lock setup (biometric / PIN).
  deviceLock,

  /// Network error during server identity check — user decides what to do.
  networkError,

  /// All done — transition to app.
  complete,
}

/// Orchestrates the post-authentication onboarding flow:
///
/// 1. **Identity Check** — Check local identity first (fast path).
/// 2. **Backup Check** — Search for local + Drive backups and offer restore.
/// 3. **Server Identity** — Check if the server has an existing public key.
/// 4. **Identity Setup** — Generate or recover the encryption primary key
///    (24-word mnemonic → Ed25519 keys).
/// 5. **Device Lock** — Prompt for biometric or PIN protection on the device.
///
/// All paths converge on [onSetupComplete] which transitions to the main app.
class PostAuthGatePage extends StatefulWidget {
  const PostAuthGatePage({
    super.key,
    required this.onSetupComplete,
  });

  /// Called when all setup layers are complete and the user should enter the app.
  final VoidCallback onSetupComplete;

  @override
  State<PostAuthGatePage> createState() => _PostAuthGatePageState();
}

class _PostAuthGatePageState extends State<PostAuthGatePage> {
  _GatePhase _phase = _GatePhase.checking;
  bool _hasLocalBackup = false;
  bool _hasDriveBackup = false;
  bool _hasServerIdentity = false;
  bool _serverCheckFailed = false;

  @override
  void initState() {
    super.initState();
    _evaluateState();
  }

  // ── Phase Router ─────────────────────────────────────────────────────────

  Future<void> _evaluateState() async {
    setState(() => _phase = _GatePhase.checking);

    // Step 1: Check local identity
    final hasLocalIdentity =
        await InjectionContainer.mnemonicVault.hasIdentity();
    if (!mounted) return;

    // If user already has a local identity, skip all discovery.
    if (hasLocalIdentity) {
      _advanceToDeviceLock();
      return;
    }

    // Step 2: Check server for existing public key identity FIRST
    await _checkServerIdentity();
    if (!mounted) return;

    if (_serverCheckFailed) {
      // Network failed — don't silently create a new identity.
      // Ask the user what they want to do.
      if (mounted) setState(() => _phase = _GatePhase.networkError);
      return;
    }

    if (!_hasServerIdentity) {
      // New account (no server identity) -> skip backup check, create new identity.
      if (mounted) setState(() => _phase = _GatePhase.identitySetup);
      _navigateToSeedSetup();
      return;
    }

    // Step 3: Server identity exists. This is a returning user.
    // Check for local/cloud backups (database files)
    await _checkBackups();
    if (!mounted) return;

    if (_hasLocalBackup ||
        _hasDriveBackup ||
        !InjectionContainer.driveBackupService.isSignedIn) {
      setState(() => _phase = _GatePhase.backupRestore);
      return;
    }

    // Step 4: Server identity exists, but no backups found. Prompt for primary key recovery.
    setState(() => _phase = _GatePhase.identityDecision);
  }

  Future<void> _checkBackups() async {
    // Check local backup
    final localFile =
        await InjectionContainer.autoBackupService.latestLocalBackup();
    _hasLocalBackup = localFile != null && localFile.existsSync();

    // Check Drive backup
    if (InjectionContainer.driveBackupService.isSignedIn) {
      final driveResult =
          await InjectionContainer.driveBackupService.checkForBackup();
      _hasDriveBackup =
          driveResult.isSuccess && driveResult.valueOrNull != null;
    }
  }

  Future<void> _checkServerIdentity() async {
    _serverCheckFailed = false;
    try {
      final licenseData =
          await InjectionContainer.licenseVault.readLicenseData();
      final serverPublicKey = licenseData?['public_key'] as String?;

      if (serverPublicKey != null && serverPublicKey.isNotEmpty) {
        _hasServerIdentity = true;
      } else {
        _hasServerIdentity = false;
      }
    } catch (_) {
      // Very unlikely since we are reading from local storage,
      // but just in case JSON parsing fails.
      _hasServerIdentity = false;
      _serverCheckFailed = true;
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _navigateToRestoreDiscovery() {
    final restoreCubit = InjectionContainer.restoreCubit;
    restoreCubit.checkBackups();
    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: restoreCubit,
          child: const RestoreDiscoveryPage(),
        ),
      ),
    )
        .then((restored) async {
      if (restored == true) {
        await InjectionContainer.reopenDatabaseAfterRestore();
      }
      // After restore attempt, proceed to identity check
      final hasIdentity = await InjectionContainer.mnemonicVault.hasIdentity();
      if (!hasIdentity) {
        if (mounted) setState(() => _phase = _GatePhase.identitySetup);
        _navigateToSeedSetup();
      } else {
        _advanceToDeviceLock();
      }
    });
  }

  Future<void> _signInAndCheckDrive() async {
    setState(() => _phase = _GatePhase.checking);
    final signInResult = await InjectionContainer.driveBackupService.signIn();

    if (signInResult.isSuccess) {
      await _checkBackups();
      if (!_hasDriveBackup && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStringsAr.noBackupFoundIn),
            backgroundColor: ColorTokens.warningAmber,
          ),
        );
      }
    } else {
      if (mounted) {
        final failure = signInResult.failureOrNull;
        final isWarning = failure is ValidationFailure &&
            failure.code == 'drive_auth_cancelled';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure?.messageAr ?? AppStringsAr.googleLoginFailed),
            backgroundColor: isWarning
                ? ColorTokens.warningAmber
                : Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    // Re-evaluate state. If signed in but no backup, it will advance to identityDecision.
    _evaluateState();
  }

  void _navigateToSeedSetup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context)
          .push(
        MaterialPageRoute(builder: (_) => const SeedSetupPage()),
      )
          .then((_) {
        _advanceToDeviceLock();
      });
    });
  }

  void _navigateToSeedRecovery() {
    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(builder: (_) => const SeedRecoveryPage()),
    )
        .then((recovered) async {
      if (recovered == true) {
        _advanceToDeviceLock();
      } else {
        // Still no identity — show identity decision again or setup
        final hasIdentity =
            await InjectionContainer.mnemonicVault.hasIdentity();
        if (!hasIdentity && mounted) {
          setState(() => _phase = _GatePhase.identityDecision);
        } else {
          _advanceToDeviceLock();
        }
      }
    });
  }

  void _bypassIdentityAndContinue() {
    // User chose to skip identity recovery → generate fresh identity
    if (mounted) setState(() => _phase = _GatePhase.identitySetup);
    _navigateToSeedSetup();
  }

  void _skipRestoreAndContinue() async {
    // User chose to skip backup restore entirely
    final hasIdentity = await InjectionContainer.mnemonicVault.hasIdentity();
    if (!hasIdentity) {
      if (_hasServerIdentity) {
        if (mounted) setState(() => _phase = _GatePhase.identityDecision);
      } else {
        if (mounted) setState(() => _phase = _GatePhase.identitySetup);
        _navigateToSeedSetup();
      }
    } else {
      _advanceToDeviceLock();
    }
  }

  void _advanceToDeviceLock() async {
    if (!mounted) return;

    // Check if device lock is already set up
    final hasPin = await InjectionContainer.securityCubit.hasPinConfigured();
    if (!mounted) return;

    if (hasPin) {
      // Already configured — skip to complete
      _completeSetup();
      return;
    }

    setState(() => _phase = _GatePhase.deviceLock);
  }

  Future<void> _setupBiometric() async {
    // Show PIN dialog first (biometric requires a PIN fallback)
    await _showPinSetupDialog();
    if (!mounted) return;

    final hasBiometric =
        await InjectionContainer.securityCubit.canUseBiometric();
    if (hasBiometric) {
      await InjectionContainer.securityCubit.setBiometricEnabled(true);
    }
    _completeSetup();
  }

  Future<void> _setupPin() async {
    await _showPinSetupDialog();
    if (mounted) _completeSetup();
  }

  Future<void> _showPinSetupDialog() async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text(
            AppStringsAr.securityPinDialogTitle,
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                style: const TextStyle(color: Colors.white),
                cursorColor: ColorTokens.emerald500,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  hintText: AppStringsAr.securityPinField,
                  hintStyle: const TextStyle(color: ColorTokens.slate400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                style: const TextStyle(color: Colors.white),
                cursorColor: ColorTokens.emerald500,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  hintText: AppStringsAr.securityPinRepeat,
                  hintStyle: const TextStyle(color: ColorTokens.slate400),
                  errorText: error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: Text(
                AppStringsAr.actionCancel,
                style: TextStyle(color: ColorTokens.slate400),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorTokens.emerald600,
              ),
              onPressed: () async {
                final pin = pinCtrl.text.trim();
                final confirm = confirmCtrl.text.trim();

                if (pin.length < 4 || pin.length > 8) {
                  setDialogState(() => error = AppStringsAr.securityPinLength);
                  return;
                }
                if (pin != confirm) {
                  setDialogState(
                      () => error = AppStringsAr.securityPinMismatch);
                  return;
                }

                await InjectionContainer.securityCubit.saveNewPin(pin);
                if (dCtx.mounted) Navigator.pop(dCtx, true);
              },
              child: const Text(AppStringsAr.saveAccount),
            ),
          ],
        ),
      ),
    );

    pinCtrl.dispose();
    confirmCtrl.dispose();
  }

  void _skipDeviceLock() {
    _completeSetup();
  }

  void _completeSetup() {
    if (!mounted) return;
    setState(() => _phase = _GatePhase.complete);
    // Brief delay to show success before transitioning
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) widget.onSetupComplete();
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.lg,
            vertical: SpacingTokens.xl,
          ),
          child: switch (_phase) {
            _GatePhase.checking => _buildChecking(),
            _GatePhase.backupRestore => _buildBackupRestore(),
            _GatePhase.identityDecision => _buildIdentityDecision(),
            _GatePhase.identitySetup => _buildChecking(), // Navigating to setup
            _GatePhase.deviceLock => _buildDeviceLock(),
            _GatePhase.networkError => _buildNetworkError(),
            _GatePhase.complete => _buildComplete(),
          },
        ),
      ),
    );
  }

  Widget _buildChecking() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AuthAnimatedIcon(
            iconData: Icons.shield_rounded,
            iconColor: ColorTokens.emerald500,
          ),
          const SizedBox(height: SpacingTokens.xl),
          const CircularProgressIndicator(color: ColorTokens.emerald500),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            AppStringsAr.gateCheckingStatus,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupRestore() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const AuthAnimatedIcon(
            iconData: Icons.cloud_download_rounded,
            iconColor: ColorTokens.emerald500,
          ),
          const SizedBox(height: SpacingTokens.lg),
          const AuthTitleBlock(
            title: AppStringsAr.gateRestoreTitle,
            subtitle: AppStringsAr.gateRestoreSubtitle,
          ),
          const SizedBox(height: SpacingTokens.xl),
          if (_hasLocalBackup)
            _buildOptionCard(
              icon: Icons.phone_android_rounded,
              title: AppStringsAr.gateRestoreLocalOption,
              subtitle: AppStringsAr.gateRestoreAndKeepIdentity,
              color: ColorTokens.emerald500,
              onTap: _navigateToRestoreDiscovery,
            ),
          if (_hasDriveBackup) ...[
            const SizedBox(height: SpacingTokens.sm),
            _buildOptionCard(
              icon: Icons.cloud_rounded,
              title: AppStringsAr.gateRestoreDriveOption,
              subtitle: AppStringsAr.gateRestoreAndKeepIdentity,
              color: const Color(0xFF4285F4), // Google Blue
              onTap: _navigateToRestoreDiscovery,
            ),
          ] else if (!InjectionContainer.driveBackupService.isSignedIn) ...[
            const SizedBox(height: SpacingTokens.sm),
            _buildOptionCard(
              icon: Icons.cloud_sync_rounded,
              title: AppStringsAr.searchInGoogleDrive,
              subtitle: AppStringsAr.signInWithYour,
              color: const Color(0xFF4285F4), // Google Blue
              onTap: _signInAndCheckDrive,
            ),
          ],
          const SizedBox(height: SpacingTokens.xl),
          TextButton(
            onPressed: _skipRestoreAndContinue,
            child: Text(
              AppStringsAr.gateSkipRestore,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityDecision() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const AuthAnimatedIcon(
            iconData: Icons.vpn_key_rounded,
            iconColor: ColorTokens.emerald500,
          ),
          const SizedBox(height: SpacingTokens.lg),
          const AuthTitleBlock(
            title: AppStringsAr.identityRecoveryRequiredTitle,
            subtitle: AppStringsAr.identityRecoveryRequiredBody,
          ),
          const SizedBox(height: SpacingTokens.xl),

          // Option 1: Enter primary key (recommended)
          _buildOptionCard(
            icon: Icons.key_rounded,
            title: AppStringsAr.identityRecoveryEnterKeyAction,
            subtitle: AppStringsAr.identityRecoveryHint,
            color: ColorTokens.emerald500,
            onTap: _navigateToSeedRecovery,
          ),
          const SizedBox(height: SpacingTokens.sm),

          // Option 2: Bypass with new identity (not recommended)
          _buildOptionCard(
            icon: Icons.add_circle_outline_rounded,
            title: AppStringsAr.gateBypassIdentity,
            subtitle: AppStringsAr.identityRecoveryBypassWarning,
            color: ColorTokens.warningAmber,
            onTap: _bypassIdentityAndContinue,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceLock() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const AuthAnimatedIcon(
            iconData: Icons.fingerprint_rounded,
            iconColor: ColorTokens.emerald500,
          ),
          const SizedBox(height: SpacingTokens.lg),
          const AuthTitleBlock(
            title: AppStringsAr.gateDeviceLockTitle,
            subtitle: AppStringsAr.gateDeviceLockSubtitle,
          ),
          const SizedBox(height: SpacingTokens.xl),

          // Biometric option
          _buildOptionCard(
            icon: Icons.face_rounded,
            title: AppStringsAr.gateSetupBiometric,
            subtitle: AppStringsAr.securityBiometricReason,
            color: ColorTokens.emerald500,
            onTap: _setupBiometric,
          ),
          const SizedBox(height: SpacingTokens.sm),

          // PIN option
          _buildOptionCard(
            icon: Icons.pin_rounded,
            title: AppStringsAr.gateSetupPin,
            subtitle: AppStringsAr.securitySetPinSubtitle,
            color: ColorTokens.goldAccent,
            onTap: _setupPin,
          ),
          const SizedBox(height: SpacingTokens.xl),

          TextButton(
            onPressed: _skipDeviceLock,
            child: Text(
              AppStringsAr.gateSkipDeviceLock,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplete() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AuthAnimatedIcon(
            iconData: Icons.check_circle_rounded,
            iconColor: ColorTokens.emerald500,
          ),
          const SizedBox(height: SpacingTokens.lg),
          const AuthTitleBlock(
            title: AppStringsAr.gateSetupComplete,
            subtitle: AppStringsAr.gateSetupCompleteBody,
          ),
          const SizedBox(height: SpacingTokens.xl),
          AuthSubmitButton(
            label: AppStringsAr.gateContinueToApp,
            loading: false,
            onPressed: widget.onSetupComplete,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkError() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const AuthAnimatedIcon(
            iconData: Icons.wifi_off_rounded,
            iconColor: ColorTokens.warningAmber,
          ),
          const SizedBox(height: SpacingTokens.lg),
          const AuthTitleBlock(
            title: AppStringsAr.gateNetworkErrorTitle,
            subtitle: AppStringsAr.gateNetworkErrorSubtitle,
          ),
          const SizedBox(height: SpacingTokens.xl),

          // Option 1: Retry
          _buildOptionCard(
            icon: Icons.refresh_rounded,
            title: AppStringsAr.gateNetworkRetry,
            subtitle: AppStringsAr.gateNetworkRetryHint,
            color: ColorTokens.emerald500,
            onTap: _evaluateState,
          ),
          const SizedBox(height: SpacingTokens.sm),

          // Option 2: Enter recovery phrase manually
          _buildOptionCard(
            icon: Icons.key_rounded,
            title: AppStringsAr.gateEnterPrimaryKey,
            subtitle: AppStringsAr.identityRecoveryHint,
            color: ColorTokens.emerald500,
            onTap: _navigateToSeedRecovery,
          ),
          const SizedBox(height: SpacingTokens.sm),

          // Option 3: Create new (with explicit warning)
          _buildOptionCard(
            icon: Icons.add_circle_outline_rounded,
            title: AppStringsAr.gateNetworkCreateNew,
            subtitle: AppStringsAr.gateNetworkCreateNewWarning,
            color: ColorTokens.warningAmber,
            onTap: _bypassIdentityAndContinue,
          ),
        ],
      ),
    );
  }

  // ── Shared Widget ────────────────────────────────────────────────────────

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(SpacingTokens.md),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          size: 14,
        ),
        onTap: onTap,
      ),
    );
  }
}
