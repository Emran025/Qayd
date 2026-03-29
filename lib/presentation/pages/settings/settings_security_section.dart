import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStringsAr.securityPinDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pin1,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: AppStringsAr.securityPinField,
              ),
            ),
            TextField(
              controller: pin2,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: AppStringsAr.securityPinRepeat,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStringsAr.templateEditCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStringsAr.settingsProceed),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final a = pin1.text.trim();
    final b = pin2.text.trim();
    if (a.length < 4 || a.length > 8 || a != b) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            a != b
                ? AppStringsAr.securityPinMismatch
                : AppStringsAr.securityPinLength,
          ),
        ),
      );
      return;
    }
    await context.read<SecurityCubit>().saveNewPin(a);
    await _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStringsAr.securityPinSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(SpacingTokens.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.password_rounded),
          title: Text(AppStringsAr.securitySetPinTitle),
          subtitle: Text(AppStringsAr.securitySetPinSubtitle),
          onTap: _openPinDialog,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.lock_clock_outlined),
          title: Text(AppStringsAr.securityLockTitle),
          subtitle: Text(AppStringsAr.securityLockSubtitle),
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
              AppStringsAr.securityNeedPinFirst,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint_rounded),
          title: Text(AppStringsAr.securityBiometricTitle),
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
