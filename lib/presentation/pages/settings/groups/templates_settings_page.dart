import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/messaging/template_list_page.dart';
import 'package:qayd/presentation/pages/settings/groups/pdf_template_settings_page.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class TemplatesSettingsPage extends StatelessWidget {
  const TemplatesSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QaydAppBar(title: AppStrings.settingsGroupTemplates),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: [
          ListTile(
            leading: Icon(Icons.forum_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: Text(AppStrings.whatsappAndSmsMessage),
            subtitle: Text(AppStrings.manageAutomaticTextsWhen),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              QaydPageRoute.slideFromStart(
                builder: (_) => const NotificationTemplatesPage(),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: Text(AppStrings.formatPdfFilesAnd),
            subtitle:
                Text(AppStrings.customizeVisualIdentityLogo),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              QaydPageRoute.slideFromStart(
                builder: (_) => const PdfTemplateSettingsPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
