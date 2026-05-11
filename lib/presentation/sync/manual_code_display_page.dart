import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qayd/application/sync/manual_link_service.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

/// PRIMARY DEVICE screen.
///
/// Shows an 8-character pairing code and polls the server until the
/// Companion enters it. Then sends the bootstrap payload automatically.
///
/// This is the "WhatsApp Desktop" side: it displays the code.
class ManualCodeDisplayPage extends StatefulWidget {
  const ManualCodeDisplayPage({
    super.key,
    required this.onBootstrapSent,
  });

  /// Called after the bootstrap payload has been sent to the companion.
  final VoidCallback onBootstrapSent;

  @override
  State<ManualCodeDisplayPage> createState() => _ManualCodeDisplayPageState();
}

class _ManualCodeDisplayPageState extends State<ManualCodeDisplayPage>
    with SingleTickerProviderStateMixin {
  ManualLinkCodeResult? _codeResult;
  bool _loading = true;
  bool _waitingForCompanion = false;
  bool _companionFound = false;
  bool _timedOut = false;
  String? _error;

  Timer? _expiryTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 600; // 10 minutes

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _requestCode();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    setState(() {
      _loading = true;
      _error = null;
      _timedOut = false;
      _waitingForCompanion = false;
      _companionFound = false;
    });

    try {
      final result =
          await InjectionContainer.devicePairingFacade.generateManualLinkCode();
      if (!mounted) return;
      setState(() {
        _codeResult = result;
        _loading = false;
        _waitingForCompanion = true;
        _secondsRemaining =
            result.expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 600);
      });
      _startCountdown();
      _sendBootstrap(result.shortCode); // البدء في انتظار دخول الجهاز التابع
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppStrings.anErrorOccurred;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final remaining =
          (_codeResult!.expiresAt.difference(DateTime.now()).inSeconds)
              .clamp(0, 600);
      setState(() => _secondsRemaining = remaining);
      if (remaining <= 0) {
        t.cancel();
        setState(() {
          _timedOut = true;
          _waitingForCompanion = false;
        });
      }
    });
  }

  Future<void> _sendBootstrap(String shortCode) async {
    if (!mounted) return;

    try {
      await InjectionContainer.devicePairingFacade.sendBootstrapViaCode(
        shortCode: shortCode,
        approvalGate: () async {
          if (!mounted) return false;
          final approved = await QaydDialog.show<bool>(
            context: context,
            icon: Icons.link_rounded,
            title: AppStrings.linkNewCompanionDevicePrompt,
            content: AppStrings.linkNewCompanionDeviceDesc,
            secondaryActionLabel: AppStrings.actionCancel,
            onSecondaryAction: () => Navigator.of(context).pop(false),
            primaryActionLabel: AppStrings.actionApprove,
            onPrimaryAction: () => Navigator.of(context).pop(true),
          );
          return approved ?? false;
        },
      );
      if (!mounted) return;
      setState(() => _companionFound = true);
      widget.onBootstrapSent();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppStrings.companionBootstrapSentError;
        _waitingForCompanion = false;
      });
    }
  }

  String get _formattedTime {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.manualCodeDisplayTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _timedOut
                  ? _buildTimedOut(theme, colorScheme)
                  : _companionFound
                      ? _buildSuccess(theme, colorScheme)
                      : _error != null
                          ? _buildError(theme, colorScheme)
                          : _buildCodeDisplay(theme, colorScheme),
        ),
      ),
    );
  }

  Widget _buildCodeDisplay(ThemeData theme, ColorScheme colorScheme) {
    final code = _codeResult!.displayCode; // e.g. "A7B9-X2K4"
    final shortCode = _codeResult!.shortCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Icon(Icons.devices_rounded, size: 56, color: colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          AppStrings.manualCodeDisplayInstruction,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Code display card
        Card(
          elevation: 0,
          color: colorScheme.primaryContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              children: [
                SelectableText(
                  code,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: colorScheme.onPrimaryContainer,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shortCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.manualCodeCopied)),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(AppStrings.actionCopy),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Countdown timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined,
                size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              '$_formattedTime',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _secondsRemaining < 60
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Waiting indicator
        if (_waitingForCompanion) ...[
          ScaleTransition(
            scale: _pulseAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppStrings.manualCodeWaitingForCompanion,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        // Cancel button
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
      ],
    );
  }

  Widget _buildTimedOut(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer_off_outlined, size: 56, color: colorScheme.error),
        const SizedBox(height: 16),
        Text(
          AppStrings.manualCodeExpired,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _requestCode,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(AppStrings.regenerateQrCode),
        ),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_rounded, size: 72, color: colorScheme.primary),
        const SizedBox(height: 20),
        Text(
          AppStrings.companionBootstrapSentSuccess,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, size: 56, color: colorScheme.error),
        const SizedBox(height: 16),
        Text(_error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.error)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _requestCode,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(AppStrings.retryAction),
        ),
      ],
    );
  }
}
