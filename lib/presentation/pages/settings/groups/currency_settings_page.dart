import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/settings/currency_management_screen.dart';
import 'package:qayd/presentation/pages/settings/transfer_fees_settings_section.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class CurrencySettingsPage extends StatelessWidget {
  const CurrencySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStrings.settingsGroupCurrency),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: [
          ListTile(
            leading: Icon(
              Icons.currency_exchange_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppStrings.basicCurrencySettings),
            subtitle: Text(AppStrings.manageCurrenciesAndVirtual),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              QaydPageRoute.slideFromStart(
                builder: (ctx) => const CurrencyManagementScreen(),
              ),
            ),
          ),
           Divider(),
           _SectionTitle(AppStrings.conversionSettings),
          const TransferFeesSettingsSection(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.xs,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
