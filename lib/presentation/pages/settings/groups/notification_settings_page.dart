import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/settings/notification_settings_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationSettingsCubit(InjectionContainer.sharedPreferences),
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStringsAr.settingsGroupNotifications),
      body: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
        builder: (context, state) {
          final cubit = context.read<NotificationSettingsCubit>();

          return ListView(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            children: [
              _buildSectionHeader(context, AppStringsAr.notifDirectCategories),
              _buildSwitchTile(
                context,
                title: AppStringsAr.notifPeerActivityTitle,
                subtitle: AppStringsAr.notifPeerActivityDesc,
                value: state.peerActivity,
                icon: Icons.people_outline_rounded,
                onChanged: cubit.togglePeerActivity,
              ),
              const SizedBox(height: SpacingTokens.md),
              _buildSwitchTile(
                context,
                title: AppStringsAr.notifSelfActivityTitle,
                subtitle: AppStringsAr.notifSelfActivityDesc,
                value: state.selfActivity,
                icon: Icons.my_location_rounded,
                onChanged: cubit.toggleSelfActivity,
              ),
              const SizedBox(height: SpacingTokens.xl),

              _buildSectionHeader(context, AppStringsAr.notifMediaAlerts),
              _buildSwitchTile(
                context,
                title: AppStringsAr.notifSoundEnabled,
                subtitle: AppStringsAr.notifSoundDesc,
                value: state.soundEnabled,
                icon: Icons.volume_up_rounded,
                onChanged: cubit.toggleSound,
              ),
              const SizedBox(height: SpacingTokens.md),
              _buildSwitchTile(
                context,
                title: AppStringsAr.notifVibrationEnabled,
                subtitle: AppStringsAr.notifVibrationDesc,
                value: state.vibrationEnabled,
                icon: Icons.vibration_rounded,
                onChanged: cubit.toggleVibration,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.md, right: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        activeColor: ColorTokens.emerald500,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
