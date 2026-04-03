import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/messaging/template_list_page.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class TemplatesSettingsPage extends StatelessWidget {
  const TemplatesSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStringsAr.settingsGroupTemplates),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
        children: [
          ListTile(
            leading: Icon(Icons.forum_outlined, color: Theme.of(context).colorScheme.primary),
            title: const Text('قوالب رسائل الواتساب والـ SMS'),
            subtitle: const Text('إدارة النصوص التلقائية عند مشاركة السندات.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              QaydPageRoute.slideFromStart(
                builder: (_) => const NotificationTemplatesPage(),
              ),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined),
            title: Text('تنسيق ملفات الـ PDF (قريباً)'),
            subtitle: Text('تخصيص شعار وألوان تقارير الـ PDF المستخرجة.'),
            enabled: false,
          ),
        ],
      ),
    );
  }
}
