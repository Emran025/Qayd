import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/messaging/template_list_page.dart';
import 'package:qayd/presentation/pages/notifications/notifications_page.dart';
import 'package:qayd/presentation/pages/settings/settings_app_bar_action.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';

/// Hub for both notifications (inbox) and message templates.
class MessagingHubPage extends StatelessWidget {
  const MessagingHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStringsAr.navMessagesTab),
          actions: const [SettingsAppBarAction()],
          bottom: TabBar(
            indicatorColor: gold,
            labelColor: gold,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: AppStringsAr.messagingInboxTab),
              Tab(text: AppStringsAr.messagingTemplatesTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NotificationsPage(),
            NotificationTemplatesPage(),
          ],
        ),
      ),
    );
  }
}
