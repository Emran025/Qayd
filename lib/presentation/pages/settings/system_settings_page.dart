import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/settings/groups/appearance_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/backup_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/security_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/support_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/templates_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/notification_settings_page.dart';
import 'package:qayd/presentation/pages/settings/device_management_page.dart';
import 'package:qayd/presentation/pages/settings/sync_privacy_settings_section.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';

class SystemSettingsPage extends StatelessWidget {
  SystemSettingsPage({super.key});

  void _navTo(BuildContext context, Widget page) {
    Navigator.of(context)
        .push(QaydPageRoute.slideFromStart(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStrings.settingsSystemTitle),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        children: [
          _buildSectionHeader(context, AppStrings.settingsSectionDataSync),
          _buildSettingsTile(
            context,
            icon: Icons.cloud_done_outlined,
            title: AppStrings.settingsGroupBackup,
            subtitle: AppStrings.settingsBackupSubtitle,
            onTap: () => _navTo(context, const BackupSettingsPage()),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.sync_lock_outlined,
            title: AppStrings.settingsSyncPrivacyTitle,
            subtitle: AppStrings.settingsSyncPrivacySubtitle,
            onTap: () => _navTo(context, const SyncPrivacySettingsSection()),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.devices_outlined,
            title: 'Device Management',
            subtitle: 'Pair and revoke trusted devices',
            onTap: () => _navTo(context, const DeviceManagementPage()),
          ),
          SizedBox(height: SpacingTokens.md),
          _buildSectionHeader(context, AppStrings.settingsSectionCustomization),
          _buildSettingsTile(
            context,
            icon: Icons.palette_outlined,
            title: AppStrings.settingsGroupAppearance,
            subtitle: AppStrings.settingsAppearanceSubtitle,
            onTap: () => _navTo(context, const AppearanceSettingsPage()),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.receipt_long_outlined,
            title: AppStrings.settingsGroupTemplates,
            subtitle: AppStrings.settingsTemplatesSubtitle,
            onTap: () => _navTo(context, const TemplatesSettingsPage()),
          ),
          SizedBox(height: SpacingTokens.md),
          _buildSectionHeader(
              context, AppStrings.settingsSectionSecurityNotifications),
          _buildSettingsTile(
            context,
            icon: Icons.security_rounded,
            title: AppStrings.settingsGroupSecurity,
            subtitle: AppStrings.settingsSecuritySubtitle,
            onTap: () => _navTo(context, const SecuritySettingsPage()),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_active_outlined,
            title: AppStrings.settingsGroupNotifications,
            subtitle: AppStrings.settingsNotificationsSubtitle,
            onTap: () => _navTo(context, const NotificationSettingsPage()),
          ),
          SizedBox(height: SpacingTokens.md),
          _buildSectionHeader(context, AppStrings.settingsSectionSupport),
          _buildSettingsTile(
            context,
            icon: Icons.support_agent_rounded,
            title: AppStrings.settingsGroupSupport,
            subtitle: AppStrings.settingsSupportSubtitle,
            onTap: () => _navTo(context, const SupportSettingsPage()),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
          bottom: SpacingTokens.sm, right: 4, top: SpacingTokens.xs),
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

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: SpacingTokens.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 19),
                ),
                SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.hintColor.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
