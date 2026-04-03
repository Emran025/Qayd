import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/settings/identity_settings_section.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStringsAr.settingsGroupProfile),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: const [
          IdentitySettingsSection(),
        ],
      ),
    );
  }
}
