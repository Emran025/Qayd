import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/settings/groups/appearance_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/backup_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/security_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/support_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/templates_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/notification_settings_page.dart';
import 'package:qayd/presentation/pages/settings/sync_privacy_settings_section.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  void _navTo(BuildContext context, Widget page) {
    Navigator.of(context)
        .push(QaydPageRoute.slideFromStart(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const QaydAppBar(title: AppStringsAr.settingsSystemTitle),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        children: [
          _buildSectionHeader(context, AppStringsAr.settingsSectionDataSync),
          _buildSettingsTile(
            context,
            icon: Icons.cloud_done_outlined,
            title: AppStringsAr.settingsGroupBackup,
            subtitle: AppStringsAr.settingsBackupSubtitle,
            onTap: () => _navTo(context, const BackupSettingsPage()),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.sync_lock_outlined,
            title: AppStringsAr.settingsSyncPrivacyTitle,
            subtitle: AppStringsAr.settingsSyncPrivacySubtitle,
            onTap: () => _navTo(context, const SyncPrivacySettingsSection()),
          ),
          const SizedBox(height: SpacingTokens.md),
          _buildSectionHeader(
              context, AppStringsAr.settingsSectionCustomization),
          _buildSettingsTile(
            context,
            icon: Icons.palette_outlined,
            title: AppStringsAr.settingsGroupAppearance,
            subtitle: AppStringsAr.settingsAppearanceSubtitle,
            onTap: () => _navTo(context, const AppearanceSettingsPage()),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.receipt_long_outlined,
            title: AppStringsAr.settingsGroupTemplates,
            subtitle: AppStringsAr.settingsTemplatesSubtitle,
            onTap: () => _navTo(context, const TemplatesSettingsPage()),
          ),
          const SizedBox(height: SpacingTokens.md),
          _buildSectionHeader(
              context, AppStringsAr.settingsSectionSecurityNotifications),
          _buildSettingsTile(
            context,
            icon: Icons.security_rounded,
            title: AppStringsAr.settingsGroupSecurity,
            subtitle: AppStringsAr.settingsSecuritySubtitle,
            onTap: () => _navTo(context, const SecuritySettingsPage()),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_active_outlined,
            title: AppStringsAr.settingsGroupNotifications,
            subtitle: AppStringsAr.settingsNotificationsSubtitle,
            onTap: () => _navTo(context, const NotificationSettingsPage()),
          ),
          const SizedBox(height: SpacingTokens.md),
          _buildSectionHeader(context, AppStringsAr.settingsSectionSupport),
          _buildSettingsTile(
            context,
            icon: Icons.support_agent_rounded,
            title: AppStringsAr.settingsGroupSupport,
            subtitle: AppStringsAr.settingsSupportSubtitle,
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
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 19),
                ),
                const SizedBox(width: SpacingTokens.md),
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
                        const SizedBox(height: 2),
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
