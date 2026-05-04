import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/components/inputs/qayd_numeric_field.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';

/// PIN, app lock, and biometric toggles.
class SettingsSecuritySection extends StatefulWidget {
  const SettingsSecuritySection({super.key});

  @override
  State<SettingsSecuritySection> createState() =>
      _SettingsSecuritySectionState();
}

class _SettingsSecuritySectionState extends State<SettingsSecuritySection> {
  bool _loading = true;
  bool _hasPin = false;
  bool _lock = false;
  bool _bio = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final c = context.read<SecurityCubit>();
    final hasPin = await c.hasPinConfigured();
    final lock = await c.isLockEnabled();
    final bio = await c.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _lock = lock;
      _bio = bio;
      _loading = false;
    });
  }

  Future<void> _openPinDialog() async {
    final pin1 = TextEditingController();
    final pin2 = TextEditingController();
    final ok = await QaydDialog.show<bool>(
      context: context,
      icon: Icons.lock_outline_rounded,
      title: AppStrings.securityPinDialogTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QaydNumericField(
            controller: pin1,
            obscureText: true,
            maxLength: 8,
            label: AppStrings.securityPinField,
          ),
          SizedBox(height: SpacingTokens.md),
          QaydNumericField(
            controller: pin2,
            obscureText: true,
            maxLength: 8,
            label: AppStrings.securityPinRepeat,
          ),
        ],
      ),
      secondaryActionLabel: AppStrings.templateEditCancel,
      onSecondaryAction: () => Navigator.pop(context, false),
      primaryActionLabel: AppStrings.settingsProceed,
      onPrimaryAction: () => Navigator.pop(context, true),
    );
    
    if (ok != true || !mounted) return;
    final a = pin1.text.trim();
    final b = pin2.text.trim();
    if (a.length < 4 || a.length > 8 || a != b) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            a != b
                ? AppStrings.securityPinMismatch
                : AppStrings.securityPinLength,
          ),
        ),
      );
      return;
    }
    await context.read<SecurityCubit>().saveNewPin(a);
    await _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.securityPinSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.all(SpacingTokens.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(Icons.password_rounded),
          title: Text(AppStrings.securitySetPinTitle),
          subtitle: Text(AppStrings.securitySetPinSubtitle),
          onTap: _openPinDialog,
        ),
        SwitchListTile(
          secondary: Icon(Icons.lock_clock_outlined),
          title: Text(AppStrings.securityLockTitle),
          subtitle: Text(AppStrings.securityLockSubtitle),
          value: _lock && _hasPin,
          onChanged: !_hasPin
              ? null
              : (v) async {
                  await context.read<SecurityCubit>().setLockEnabled(v);
                  await _reload();
                },
        ),
        if (!_hasPin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
            child: Text(
              AppStrings.securityNeedPinFirst,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        SwitchListTile(
          secondary: Icon(Icons.fingerprint_rounded),
          title: Text(AppStrings.securityBiometricTitle),
          value: _bio && _hasPin,
          onChanged: !_hasPin
              ? null
              : (v) async {
                  await context.read<SecurityCubit>().setBiometricEnabled(v);
                  await _reload();
                },
        ),
      ],
    );
  }
}
