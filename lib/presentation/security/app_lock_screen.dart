import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/security/security_state.dart';
import 'package:qayd/presentation/security/security_lock_overlay.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';

/// Full-screen unlock UI (Themed).
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _pin = '';
  bool _bioAvailable = false;

  static const int _minLen = 4;
  static const int _maxLen = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await context.read<SecurityCubit>().canUseBiometric();
      if (mounted) setState(() => _bioAvailable = ok);
    });
  }

  Future<void> _tryBiometric() async {
    await context.read<SecurityCubit>().unlockWithBiometric(
          localizedReason: AppStringsAr.securityBiometricReason,
        );
  }

  void _addDigit(String d) {
    if (_pin.length >= _maxLen) return;
    setState(() => _pin += d);
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_pin.length < _minLen) return;
    final wasLocked = context.read<SecurityCubit>().state.isLocked;
    await context.read<SecurityCubit>().unlockWithPin(_pin);
    if (!mounted) return;
    final stillLocked = context.read<SecurityCubit>().state.isLocked;
    if (wasLocked && stillLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStringsAr.securityPinWrong)),
      );
    }
    setState(() => _pin = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme;
    final customColors = theme.extension<QaydCustomColors>();
    final accentColor = customColors?.goldAccent ?? theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            children: [
              const SizedBox(height: SpacingTokens.xl),
              Icon(
                Icons.lock_rounded,
                size: 56,
                color: accentColor.withValues(alpha: 0.95),
              ),
              const SizedBox(height: SpacingTokens.md),
              Text(
                AppStringsAr.lockScreenTitle,
                style: textStyle.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                AppStringsAr.lockScreenSubtitle,
                style: textStyle.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              BlocBuilder<SecurityCubit, SecurityState>(
                builder: (context, state) {
                  if (state.trialDaysRemaining != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: SpacingTokens.md),
                      child:
                          SecurityTrialBadge(days: state.trialDaysRemaining!),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: SpacingTokens.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.lg,
                  vertical: SpacingTokens.md,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _maxLen,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _pin.length ? Icons.circle : Icons.circle_outlined,
                        size: 14,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: SpacingTokens.lg),
              Expanded(
                child: _Keypad(
                  onDigit: _addDigit,
                  onBackspace: _backspace,
                ),
              ),
              if (_bioAvailable)
                Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: Icon(Icons.fingerprint_rounded, color: accentColor),
                    label: Text(
                      AppStringsAr.biometricUnlock,
                      style: textStyle.labelLarge?.copyWith(
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _pin.length >= _minLen ? _submit : null,
                  child: Text(
                    AppStringsAr.unlockAction,
                    style: textStyle.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final cell in row)
                      _KeyCell(
                        label: cell,
                        onTap: () {
                          if (cell == '⌫') {
                            onBackspace();
                          } else if (cell.isNotEmpty) {
                            onDigit(cell);
                          }
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KeyCell extends StatelessWidget {
  const _KeyCell({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (label.isEmpty) {
      return const SizedBox(width: 72, height: 52);
    }
    return SizedBox(
      width: 72,
      height: 52,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: label == '⌫' ? 20 : 22,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
