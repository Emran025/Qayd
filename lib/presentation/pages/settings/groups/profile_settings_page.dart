import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/settings/identity_settings_section.dart';
import 'package:qayd/presentation/pages/settings/profile_details_section.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStringsAr.settingsGroupProfile),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: const [
          ProfileDetailsSection(),
          Divider(height: 32),
          IdentitySettingsSection(),
        ],
      ),
    );
  }
}
