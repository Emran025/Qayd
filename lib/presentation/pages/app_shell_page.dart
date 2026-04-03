import 'package:flutter/material.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/accounts/account_list_page.dart';
import 'package:qayd/presentation/pages/messaging/messaging_hub_page.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_page.dart';
import 'package:qayd/presentation/pages/vouchers/tripartite_list_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_page.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/widgets/settings_sidebar.dart';

/// Bottom navigation between chart of accounts and vouchers (Phase 1 hub).
class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return Scaffold(
      drawer: const SettingsSidebar(),
      body: IndexedStack(
        index: _index,
        children: const [
          VoucherListPage(),
          TripartiteListPage(),
          AccountListPage(),
          TrialBalancePage(),
          MessagingHubPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        indicatorColor: gold.withValues(alpha: 0.35),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: gold),
            label: AppStringsAr.navVouchersTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horizontal_circle_rounded, color: gold),
            label: AppStringsAr.navTripartiteTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: gold),
            label: AppStringsAr.navAccountsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart_rounded, color: gold),
            label: AppStringsAr.navReportsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded, color: gold),
            label: AppStringsAr.navMessagesTab,
          ),
        ],
      ),
    );
  }
}
