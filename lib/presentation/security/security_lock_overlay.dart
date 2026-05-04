import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/security/security_state.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// App-wide vault overlay.
///
/// Renders on top of the entire app when:
///   - License is expired / pending / revoked / device-unbound.
///   - Clock has been tampered.
///
/// The PIN lock screen is handled separately in [AppLockScreen].
class SecurityLockOverlay extends StatefulWidget {
  const SecurityLockOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<SecurityLockOverlay> createState() => _SecurityLockOverlayState();
}

class _SecurityLockOverlayState extends State<SecurityLockOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (context, state) {
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (state.isHardBlocked)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) => _VaultScreen(state: state),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _VaultScreen extends StatelessWidget {
  const _VaultScreen({required this.state});

  final SecurityState state;

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig(state);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF020617), // slate-950
              Color(0xFF0A1628), // navy-950
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.lg,
              vertical: SpacingTokens.xl,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AnimatedIcon(iconData: config.icon, color: config.iconColor),
                SizedBox(height: SpacingTokens.lg),
                Text(
                  config.titleAr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ColorTokens.slate50,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: SpacingTokens.sm),
                Text(
                  config.bodyAr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorTokens.slate400,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (config.trialDaysRemaining != null) ...[
                  SizedBox(height: SpacingTokens.md),
                  SecurityTrialBadge(days: config.trialDaysRemaining!),
                ],
                SizedBox(height: SpacingTokens.xl),
                if (config.showProvisioningButton)
                  _ProvisioningButton(config: config),
                if (config.showRefreshButton) const _RefreshStatusButton(),
                if (config.showContactButton) ...[
                  if (config.showRefreshButton || config.showProvisioningButton)
                    SizedBox(height: SpacingTokens.md),
                  _ContactBadge(messageAr: config.contactAr ?? ''),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  _OverlayConfig _resolveConfig(SecurityState state) {
    final ls = state.licenseStatus;
    final cs = state.clockStatus;

    if (cs == ClockStatus.tampered) {
      return _OverlayConfig(
        icon: Icons.history_toggle_off_rounded,
        iconColor: const Color(0xFFDC2626), // crimson-600
        titleAr: AppStrings.vaultClockTamperedTitle,
        bodyAr: AppStrings.vaultClockTamperedBody,
        showContactButton: true,
        contactAr: AppStrings.vaultContactSupport,
        trialDaysRemaining: state.trialDaysRemaining,
      );
    }

    switch (ls) {
      case LicenseStatus.pending:
        return _OverlayConfig(
          icon: Icons.verified_user_rounded,
          iconColor: ColorTokens.goldAccent,
          titleAr: AppStrings.vaultPendingTitle,
          bodyAr: AppStrings.vaultPendingBody,
          showProvisioningButton: true,
          trialDaysRemaining: state.trialDaysRemaining,
        );
      case LicenseStatus.trialExpired:
        return _OverlayConfig(
          icon: Icons.hourglass_disabled_rounded,
          iconColor: const Color(0xFFDC2626),
          titleAr: AppStrings.vaultTrialExpiredTitle,
          bodyAr: AppStrings.vaultTrialExpiredBody,
          showRefreshButton: true,
          showContactButton: true,
          contactAr: AppStrings.vaultContactSupport,
          trialDaysRemaining: state.trialDaysRemaining,
        );
      case LicenseStatus.revoked:
        return _OverlayConfig(
          icon: Icons.block_rounded,
          iconColor: const Color(0xFFDC2626),
          titleAr: AppStrings.vaultRevokedTitle,
          bodyAr: AppStrings.vaultRevokedBody,
          showContactButton: true,
          contactAr: AppStrings.vaultContactSupport,
          trialDaysRemaining: state.trialDaysRemaining,
        );
      case LicenseStatus.deviceUnbound:
        return _OverlayConfig(
          icon: Icons.devices_other_rounded,
          iconColor: const Color(0xFFDC2626),
          titleAr: AppStrings.vaultDeviceUnboundTitle,
          bodyAr: AppStrings.vaultDeviceUnboundBody,
          showContactButton: true,
          contactAr: AppStrings.vaultContactSupport,
          trialDaysRemaining: state.trialDaysRemaining,
        );
      default:
        return _OverlayConfig(
          icon: Icons.lock_rounded,
          iconColor: ColorTokens.goldAccent,
          titleAr: AppStrings.lockScreenTitle,
          bodyAr: AppStrings.lockScreenSubtitle,
          trialDaysRemaining: state.trialDaysRemaining,
        );
    }
  }
}

class _AnimatedIcon extends StatefulWidget {
  const _AnimatedIcon({required this.iconData, required this.color});

  final IconData iconData;
  final Color color;

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.12),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Icon(widget.iconData, size: 48, color: widget.color),
      ),
    );
  }
}

class SecurityTrialBadge extends StatelessWidget {
  const SecurityTrialBadge({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorTokens.emerald500.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ColorTokens.emerald500.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        '$days ${AppStrings.vaultTrialDaysRemaining}',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ColorTokens.emerald400,
        ),
      ),
    );
  }
}

class _ProvisioningButton extends StatefulWidget {
  const _ProvisioningButton({required this.config});

  final _OverlayConfig config;

  @override
  State<_ProvisioningButton> createState() => _ProvisioningButtonState();
}

class _ProvisioningButtonState extends State<_ProvisioningButton> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _errorAr;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _errorAr = null;
    });
    final result = await context.read<SecurityCubit>().provisionDevice(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!result.success) {
      setState(() => _errorAr = result.errorAr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldStyle = const TextStyle(
      fontFamily: 'Cairo',
      fontSize: 14,
      color: ColorTokens.slate50,
    );
    final borderColor = ColorTokens.slate200.withValues(alpha: 0.2);

    return Column(
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _emailCtrl,
            style: fieldStyle,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: AppStrings.vaultEmailHint,
              hintStyle: fieldStyle.copyWith(color: ColorTokens.slate400),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ColorTokens.emerald500.withValues(alpha: 0.7),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        SizedBox(height: SpacingTokens.sm),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _passCtrl,
            style: fieldStyle,
            obscureText: true,
            decoration: InputDecoration(
              hintText: AppStrings.vaultPasswordHint,
              hintStyle: fieldStyle.copyWith(color: ColorTokens.slate400),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ColorTokens.emerald500.withValues(alpha: 0.7),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (_errorAr != null) ...[
          SizedBox(height: SpacingTokens.sm),
          Text(
            _errorAr!,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: Color(0xFFF87171), // red-400
            ),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: SpacingTokens.md),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.emerald500,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppStrings.vaultActivateAction,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ContactBadge extends StatelessWidget {
  const _ContactBadge({required this.messageAr});

  final String messageAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        messageAr,
        style: const TextStyle(
            fontFamily: 'Cairo', fontSize: 12, color: ColorTokens.slate400),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _RefreshStatusButton extends StatefulWidget {
  const _RefreshStatusButton();

  @override
  State<_RefreshStatusButton> createState() => _RefreshStatusButtonState();
}

class _RefreshStatusButtonState extends State<_RefreshStatusButton> {
  bool _loading = false;
  String? _errorAr;

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _errorAr = null;
    });

    final result = await context.read<SecurityCubit>().refreshLicenseStatus();

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      setState(() => _errorAr = result.errorAr);
    } else if (context.read<SecurityCubit>().state.isHardBlocked) {
      // It succeeded but the account is still locked
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.theAccountStatusHas),
          backgroundColor: ColorTokens.slate800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.slate800,
              foregroundColor: ColorTokens.emerald400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                    color: ColorTokens.emerald500.withValues(alpha: 0.3)),
              ),
            ),
            onPressed: _loading ? null : _refresh,
            icon: _loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorTokens.emerald400,
                    ),
                  )
                : Icon(Icons.refresh_rounded),
            label: Text(
              AppStrings.updateAccountStatus,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (_errorAr != null) ...[
          SizedBox(height: SpacingTokens.sm),
          Text(
            _errorAr!,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: Color(0xFFF87171), // red-400
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _OverlayConfig {
  const _OverlayConfig({
    required this.icon,
    required this.iconColor,
    required this.titleAr,
    required this.bodyAr,
    this.trialDaysRemaining,
    this.showProvisioningButton = false,
    this.showRefreshButton = false,
    this.showContactButton = false,
    this.contactAr,
  });

  final IconData icon;
  final Color iconColor;
  final String titleAr;
  final String bodyAr;
  final int? trialDaysRemaining;
  final bool showProvisioningButton;
  final bool showRefreshButton;
  final bool showContactButton;
  final String? contactAr;
}
