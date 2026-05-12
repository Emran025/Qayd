import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qayd/application/sync/manual_link_service.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// PRIMARY DEVICE screen.
///
/// Shows an 8-character pairing code and polls the server until the
/// Companion enters it. Then sends the bootstrap payload automatically.
class ManualCodeDisplayPage extends StatefulWidget {
  const ManualCodeDisplayPage({
    super.key,
    required this.onBootstrapSent,
  });

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

  Timer? _countdownTimer;
  int _secondsRemaining = 600;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _requestCode();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!mounted) return;
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
      _sendBootstrap(result.shortCode);
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
    return AuthGradientScaffold(
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: SpacingTokens.lg),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 60),
                                if (_timedOut)
                                  _buildTimedOut()
                                else if (_companionFound)
                                  _buildSuccess()
                                else if (_error != null)
                                  _buildError()
                                else
                                  _buildCodeDisplay(),
                                const SizedBox(height: 60),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Back Button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: ColorTokens.slate400, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeDisplay() {
    final shortCode = _codeResult!.shortCode; // e.g. "A7B9X2K4"

    return Column(
      children: [
        const AuthAnimatedIcon(
          iconData: Icons.devices_rounded,
          iconColor: ColorTokens.emerald500,
        ),
        const SizedBox(height: SpacingTokens.lg),
        AuthTitleBlock(
          title: AppStrings.manualCodeDisplayTitle,
          subtitle: AppStrings.manualCodeDisplayInstruction,
        ),
        const SizedBox(height: SpacingTokens.xl),

        // Premium Segmented Code Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: ColorTokens.navy900.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCodeGroup(shortCode.substring(0, 4)),
                      const SizedBox(width: 16),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ColorTokens.slate400.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildCodeGroup(shortCode.substring(4, 8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Modern Pill Copy Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: shortCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.manualCodeCopied),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: ColorTokens.emerald600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: ColorTokens.emerald500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      border: Border.all(
                        color: ColorTokens.emerald500.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_all_rounded,
                            size: 18, color: ColorTokens.emerald400),
                        const SizedBox(width: 10),
                        Text(
                          AppStrings.actionCopy,
                          style: const TextStyle(
                            color: ColorTokens.emerald400,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Timer and Waiting State
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined,
                size: 18,
                color: _secondsRemaining < 60
                    ? ColorTokens.errorSoft
                    : ColorTokens.slate400),
            const SizedBox(width: 8),
            Text(
              _formattedTime,
              style: TextStyle(
                color: _secondsRemaining < 60
                    ? ColorTokens.errorSoft
                    : ColorTokens.slate400,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),

        if (_waitingForCompanion)
          FadeTransition(
            opacity: _pulseAnimation,
            child: Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ColorTokens.emerald500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.manualCodeWaitingForCompanion,
                  style: const TextStyle(
                    color: ColorTokens.slate400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimedOut() {
    return Column(
      children: [
        const AuthAnimatedIcon(
          iconData: Icons.timer_off_outlined,
          iconColor: ColorTokens.errorSoft,
        ),
        const SizedBox(height: SpacingTokens.lg),
        AuthTitleBlock(
          title: AppStrings.manualCodeExpired,
          subtitle: AppStrings.manualCodeExpiredDesc, // Add if exists
        ),
        const SizedBox(height: SpacingTokens.xl),
        AuthSubmitButton(
          label: AppStrings.regenerateQrCode,
          onPressed: _requestCode,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const AuthAnimatedIcon(
          iconData: Icons.check_circle_rounded,
          iconColor: ColorTokens.emerald500,
        ),
        const SizedBox(height: SpacingTokens.lg),
        AuthTitleBlock(
          title: AppStrings.companionBootstrapSentSuccess,
          subtitle: AppStrings.companionBootstrapSentSuccessDesc,
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        const AuthAnimatedIcon(
          iconData: Icons.error_outline_rounded,
          iconColor: ColorTokens.errorSoft,
        ),
        const SizedBox(height: SpacingTokens.lg),
        AuthTitleBlock(
          title: AppStrings.anErrorOccurred,
          subtitle: _error ?? '',
        ),
        const SizedBox(height: SpacingTokens.xl),
        AuthSubmitButton(
          label: AppStrings.retryAction,
          onPressed: _requestCode,
        ),
      ],
    );
  }

  Widget _buildCodeGroup(String part) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: part.split('').map((char) => _buildCodeChar(char)).toList(),
    );
  }

  Widget _buildCodeChar(String char) {
    return Container(
      width: 44,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          char,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
