import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/settings_sidebar.dart';

class SupportSettingsPage extends StatelessWidget {
  const SupportSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStringsAr.settingsGroupSupport),
      ),
      drawer: const SettingsSidebar(),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: [
          ListTile(
            leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStringsAr.settingsFaqs),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.headset_mic_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStringsAr.settingsContactSupport),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.bug_report_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStringsAr.settingsReportIssue),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStringsAr.settingsPrivacyPolicy),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(AppStringsAr.settingsTermsOfUse),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppStringsAr.settingsVersionInfo),
            subtitle: const Text('الإصدار v2.1.0-stable'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
