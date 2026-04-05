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
import 'package:qayd/presentation/widgets/identity_qr_dialog.dart';

class SettingsSidebar extends StatelessWidget {
  const SettingsSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          // Header مع تصميم مودرن
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height < 500 ? 120 : 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
              ),
            ),
            child: Stack(
              children: [
                // لمسة جمالية في الخلفية (دوائر شفافة)
                Positioned(
                  top: -20,
                  right: -20,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.settings_suggest_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        AppStringsAr.settingsTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // القائمة
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
              children: [
                _DrawerTile(
                  icon: Icons.person_outline_rounded,
                  title: AppStringsAr.settingsGroupProfile,
                  onTap: () => _navTo(context, const ProfileSettingsPage()),
                ),
                _DrawerTile(
                  icon: Icons.qr_code_scanner_rounded,
                  title: AppStringsAr.identityQrShowTitle,
                  onTap: () {
                    Navigator.pop(context);
                    IdentityQrDialog.show(context);
                  },
                ),
                const Divider(
                  indent: 20,
                  endIndent: 20,
                  height: 30,
                  thickness: 0.5,
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
                  icon: Icons.security_rounded,
                  title: AppStringsAr.settingsGroupSecurity,
                  onTap: () => _navTo(context, const SecuritySettingsPage()),
                ),
                const Divider(
                  indent: 20,
                  endIndent: 20,
                  height: 30,
                  thickness: 0.5,
                ),
                _DrawerTile(
                  icon: Icons.support_agent_rounded,
                  title: AppStringsAr.settingsGroupSupport,
                  onTap: () => _navTo(context, const SupportSettingsPage()),
                ),
              ],
            ),
          ),

          // // الإصدار في الأسفل
          // Padding(
          //   padding: const EdgeInsets.all(SpacingTokens.lg),
          //   child: Text(
          //     'قيد v2.1.0',
          //     style: theme.textTheme.bodySmall?.copyWith(
          //       color: theme.hintColor.withValues(alpha: 0.6),
          //       fontWeight: FontWeight.w600,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  void _navTo(BuildContext context, Widget page) {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(QaydPageRoute.slideFromStart(builder: (_) => page));
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // تأثير تمييز خفيف عند الحواف
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                // أيقونة داخل خلفية دائرية خفيفة
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.hintColor.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
