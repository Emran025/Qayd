import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/settings/settings_security_section.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStringsAr.settingsGroupSecurity),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: const [
          SettingsSecuritySection(),
        ],
      ),
    );
  }
}
