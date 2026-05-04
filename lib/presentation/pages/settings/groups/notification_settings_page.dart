import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
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

class _NotificationSettingsView extends StatefulWidget {
  const _NotificationSettingsView();

  @override
  State<_NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<_NotificationSettingsView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check permission when user returns from system settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationSettingsCubit>().checkOsPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStrings.settingsGroupNotifications),
      body: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
        builder: (context, state) {
          final cubit = context.read<NotificationSettingsCubit>();

          return ListView(
            padding:  EdgeInsets.all(SpacingTokens.lg),
            children: [
              // ── OS Permission Banner ──────────────────────────────────
              if (!state.osPermissionGranted) _buildPermissionDeniedBanner(context),
              if (state.osPermissionGranted) _buildPermissionGrantedBanner(context),

              SizedBox(height: SpacingTokens.md),

              // ── Categories ────────────────────────────────────────────
              _buildSectionHeader(context, AppStrings.notifDirectCategories),
              _buildSwitchTile(
                context,
                title: AppStrings.notifPeerActivityTitle,
                subtitle: AppStrings.notifPeerActivityDesc,
                value: state.peerActivity,
                icon: Icons.people_outline_rounded,
                onChanged: state.osPermissionGranted ? cubit.togglePeerActivity : null,
              ),
              SizedBox(height: SpacingTokens.sm),
              _buildSwitchTile(
                context,
                title: AppStrings.notifSelfActivityTitle,
                subtitle: AppStrings.notifSelfActivityDesc,
                value: state.selfActivity,
                icon: Icons.my_location_rounded,
                onChanged: state.osPermissionGranted ? cubit.toggleSelfActivity : null,
              ),
              SizedBox(height: SpacingTokens.lg),

              // ── Media ─────────────────────────────────────────────────
              _buildSectionHeader(context, AppStrings.notifMediaAlerts),
              _buildSwitchTile(
                context,
                title: AppStrings.notifSoundEnabled,
                subtitle: AppStrings.notifSoundDesc,
                value: state.soundEnabled,
                icon: Icons.volume_up_rounded,
                onChanged: state.osPermissionGranted ? cubit.toggleSound : null,
              ),
              SizedBox(height: SpacingTokens.sm),
              _buildSwitchTile(
                context,
                title: AppStrings.notifVibrationEnabled,
                subtitle: AppStrings.notifVibrationDesc,
                value: state.vibrationEnabled,
                icon: Icons.vibration_rounded,
                onChanged: state.osPermissionGranted ? cubit.toggleVibration : null,
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Permission Denied Banner ────────────────────────────────────────────

  Widget _buildPermissionDeniedBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding:  EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorTokens.errorDeep.withOpacity(0.12),
            ColorTokens.errorSoft.withOpacity(0.06),
          ],
          begin: AlignmentDirectional.topEnd,
          end: AlignmentDirectional.bottomStart,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorTokens.errorSoft.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:  EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorTokens.errorSoft.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notifications_off_rounded,
                  color: ColorTokens.errorSoft,
                  size: 22,
                ),
              ),
              SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.notifPermissionDeniedTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ColorTokens.errorSoft,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      AppStrings.notifPermissionDeniedBody,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => openAppSettings(),
              icon: Icon(Icons.settings_rounded, size: 16),
              label: Text(
                AppStrings.notifPermissionOpenSettings,
                style: const TextStyle(fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.errorSoft,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Permission Granted Banner ───────────────────────────────────────────

  Widget _buildPermissionGrantedBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding:  EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm + 2,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.goldAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorTokens.goldAccent.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding:  EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: ColorTokens.goldAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: ColorTokens.goldAccent,
              size: 18,
            ),
          ),
          SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.notifPermissionGranted,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorTokens.goldAccent,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  AppStrings.notifPermissionGrantedBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ──────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm, right: 4),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Switch Tile ─────────────────────────────────────────────────────────

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool)? onChanged,
  }) {
    final theme = Theme.of(context);
    final disabled = onChanged == null;

    return AnimatedOpacity(
      duration:  Duration(milliseconds: 250),
      opacity: disabled ? 0.45 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        ),
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          secondary: Container(
            padding:  EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 19),
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontSize: 11,
            ),
          ),
          activeColor: ColorTokens.goldAccent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          dense: true,
        ),
      ),
    );
  }
}
