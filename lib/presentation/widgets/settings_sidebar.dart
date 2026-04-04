import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/settings/groups/backup_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/currency_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/profile_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/security_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/support_settings_page.dart';
import 'package:qayd/presentation/pages/settings/groups/templates_settings_page.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class SettingsSidebar extends StatelessWidget {
  const SettingsSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Theme.of(context).colorScheme.tertiary,
                  Theme.of(context).colorScheme.tertiary,
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary,
                ],
                stops: const [0.0, 0.5, 0.5, 1.0],
              ),
            ),
            child: Center(
              child: Text(
                AppStringsAr.settingsTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
              ),
            ),
          ),
          _DrawerTile(
            icon: Icons.person_outline,
            title: AppStringsAr.settingsGroupProfile,
            onTap: () => _navTo(context, const ProfileSettingsPage()),
          ),
          _DrawerTile(
            icon: Icons.cloud_done_outlined,
            title: AppStringsAr.settingsGroupBackup,
            onTap: () => _navTo(context, const BackupSettingsPage()),
          ),
          _DrawerTile(
            icon: Icons.receipt_long_outlined,
            title: AppStringsAr.settingsGroupTemplates,
            onTap: () => _navTo(context, const TemplatesSettingsPage()),
          ),
          _DrawerTile(
            icon: Icons.currency_exchange_rounded,
            title: AppStringsAr.settingsGroupCurrency,
            onTap: () => _navTo(context, const CurrencySettingsPage()),
          ),
          _DrawerTile(
            icon: Icons.lock_outline,
            title: AppStringsAr.settingsGroupSecurity,
            onTap: () => _navTo(context, const SecuritySettingsPage()),
          ),
          _DrawerTile(
            icon: Icons.support_agent_outlined,
            title: AppStringsAr.settingsGroupSupport,
            onTap: () => _navTo(context, const SupportSettingsPage()),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Text(
              'قيد v2.1.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _navTo(BuildContext context, Widget page) {
    Navigator.of(context).pop(); // Close drawer
    Navigator.of(context).push(
      QaydPageRoute.slideFromStart(builder: (_) => page),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
