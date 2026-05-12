import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/device_session.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/security/security_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = ColorTokens.errorSoft;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(Icons.logout_rounded, color: color, size: 22),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    AppStrings.logoutAction,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final isCompanion =
        await InjectionContainer.licenseVault.isCompanionDevice();
    if (!context.mounted) return;

    if (isCompanion) {
      await QaydDialog.show<void>(
        context: context,
        title: AppStrings.logoutConfirmTitle,
        content: AppStrings.logoutConfirmBody,
        icon: Icons.logout_rounded,
        iconColor: ColorTokens.errorSoft,
        primaryActionLabel: AppStrings.logoutAction,
        onPrimaryAction: () {
          Navigator.pop(context);
          context.read<SecurityCubit>().logout();
        },
        secondaryActionLabel: AppStrings.actionCancel,
        onSecondaryAction: () => Navigator.pop(context),
      );
      return;
    }

    List<DeviceSession> sessions = const [];
    try {
      sessions =
          await InjectionContainer.deviceRegistryRepository.listDevices();
    } catch (_) {}

    final currentId = InjectionContainer.currentDeviceId;
    final candidates = sessions
        .where((s) =>
            s.isActive &&
            !s.isCurrent &&
            s.deviceId != currentId &&
            (s.role == 'companion' || s.role == null || s.role!.isEmpty))
        .toList()
      ..sort((a, b) => a.pairedAt.compareTo(b.pairedAt));
    final successor =
        candidates.isEmpty ? null : candidates.first;

    if (!context.mounted) return;

    if (successor != null) {
      await QaydDialog.show<void>(
        context: context,
        title: AppStrings.logoutPrimaryHandoverTitle,
        content: AppStrings.logoutPrimaryHandoverTemplate(
          successor.deviceName ?? successor.deviceId,
        ),
        icon: Icons.swap_horiz_rounded,
        iconColor: ColorTokens.errorSoft,
        primaryActionLabel: AppStrings.logoutAction,
        onPrimaryAction: () {
          Navigator.pop(context);
          context.read<SecurityCubit>().logout();
        },
        secondaryActionLabel: AppStrings.actionCancel,
        onSecondaryAction: () => Navigator.pop(context),
      );
    } else {
      await QaydDialog.show<void>(
        context: context,
        title: AppStrings.logoutConfirmTitle,
        content: AppStrings.logoutConfirmBody,
        icon: Icons.logout_rounded,
        iconColor: ColorTokens.errorSoft,
        primaryActionLabel: AppStrings.logoutAction,
        onPrimaryAction: () {
          Navigator.pop(context);
          context.read<SecurityCubit>().logout();
        },
        secondaryActionLabel: AppStrings.actionCancel,
        onSecondaryAction: () => Navigator.pop(context),
      );
    }
  }
}
