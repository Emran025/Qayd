import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/settings/identity_settings_section.dart';
import 'package:qayd/presentation/pages/settings/profile_details_section.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/core/result/result.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStrings.settingsGroupProfile),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: [
          const ProfileDetailsSection(),
          const Divider(height: 32),
          const IdentitySettingsSection(),
          const Divider(height: 32),
          _DeleteAccountSection(),
        ],
      ),
    );
  }
}

class _DeleteAccountSection extends StatefulWidget {
  const _DeleteAccountSection();

  @override
  State<_DeleteAccountSection> createState() => _DeleteAccountSectionState();
}

class _DeleteAccountSectionState extends State<_DeleteAccountSection> {
  bool _loading = false;
  bool _hideForCompanion = false;

  @override
  void initState() {
    super.initState();
    _loadCompanionGate();
  }

  Future<void> _loadCompanionGate() async {
    final isCompanion =
        await InjectionContainer.licenseVault.isCompanionDevice();
    if (mounted) {
      setState(() => _hideForCompanion = isCompanion);
    }
  }

  Future<void> _confirmDelete() async {
    setState(() => _loading = true);
    bool hasInternet = false;
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        hasInternet = true;
      }
    } catch (_) {
      hasInternet = false;
    }
    setState(() => _loading = false);

    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.internetConnectionFailedPlease),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    bool confirmed = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return QaydDialog(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.red,
            title: AppStrings.profileDeleteAccountWarningTitle,
            primaryActionLabel: AppStrings.profileDeleteAccountExecute,
            onPrimaryAction: !confirmed
                ? null
                : () {
                    Navigator.pop(ctx);
                    _executeDelete();
                  },
            secondaryActionLabel: AppStrings.templateEditCancel,
            onSecondaryAction: () => Navigator.pop(ctx),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.profileDeleteAccountWarningBody,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                SizedBox(height: SpacingTokens.md),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    AppStrings.profileDeleteAccountConfirmLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: confirmed,
                  onChanged: (val) =>
                      setDialogState(() => confirmed = val ?? false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _executeDelete() async {
    setState(() => _loading = true);

    final result = await InjectionContainer.deleteAccountUseCase.call();

    if (mounted) {
      setState(() => _loading = false);

      if (result.isSuccess) {
        // Clean up security state
        await context.read<SecurityCubit>().logout();

        // Navigate to the root (which should now show Login/Onboarding as data is wiped)
        if (mounted) {
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil('/', (route) => false);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.profileDeleteAccountSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result.failureOrNull?.messageAr ?? AppStrings.anErrorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hideForCompanion) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
      color: scheme.errorContainer.withValues(alpha: 0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        side: BorderSide(color: scheme.error.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.xs),
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: scheme.error, size: 20),
                ),
                SizedBox(width: SpacingTokens.md),
                QaydText(
                  AppStrings.dangerZone,
                  slot: QaydTextStyleSlot.titleMedium,
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.md),
            QaydText(
              AppStrings.accountErasureIsA,
              slot: QaydTextStyleSlot.bodySmall,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(height: SpacingTokens.lg),
            OutlinedButton.icon(
              onPressed: _loading ? null : _confirmDelete,
              icon: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.delete_forever_rounded),
              label: Text(AppStrings.profileDeleteAccountAction),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
