import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/backup/restore_cubit.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/accounts/account_list_page.dart';
import 'package:qayd/presentation/pages/backup/restore_discovery_page.dart';
import 'package:qayd/presentation/pages/notifications/notifications_page.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_page.dart';
import 'package:qayd/presentation/pages/vouchers/tripartite_list_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_page.dart';
import 'package:qayd/presentation/sync/sync_status_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';

import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _index = 0;
  bool _showRestorePrompt = false;

  @override
  void initState() {
    super.initState();
    _checkEmptyDb();
  }

  Future<void> _checkEmptyDb() async {
    final result = await InjectionContainer.accountRepository.hasAnyAccounts();
    final isEmpty = result.fold((_) => false, (hasAccounts) => !hasAccounts);

    if (isEmpty) {
      // Check if any backups exist
      final restoreCubit = InjectionContainer.restoreCubit;
      await restoreCubit.checkBackups();
      if (restoreCubit.state is RestoreFound) {
        if (mounted) setState(() => _showRestorePrompt = true);
      }
    }
  }

  Future<void> _navigateToRestore() async {
    final restoreCubit = InjectionContainer.restoreCubit;
    final restored = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: restoreCubit,
          child: const RestoreDiscoveryPage(),
        ),
      ),
    );

    if (restored == true) {
      await InjectionContainer.reopenDatabaseAfterRestore();
      if (mounted) setState(() => _showRestorePrompt = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    return QaydScaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              VoucherListPage(),
              TripartiteListPage(),
              AccountListPage(),
              TrialBalancePage(),
              NotificationsPage(),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  if (_showRestorePrompt)
                    _buildRestoreBanner(context),
                  BlocBuilder<SyncStatusCubit, SyncStatusState>(
                    bloc: InjectionContainer.syncStatusCubit,
                    builder: (context, state) {
                      if (state.status == SyncStatus.decryptionMismatch) {
                        return _buildMismatchBanner(context);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
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

  Widget _buildRestoreBanner(BuildContext context) {
    return Material(
      color: ColorTokens.emerald600.withOpacity(0.9),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.restore_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'وجدنا نسخة احتياطية محلية، هل تريد استعادة بياناتك السابقة؟',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _navigateToRestore,
              child: const Text('استعادة الآن', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: () => setState(() => _showRestorePrompt = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMismatchBanner(BuildContext context) {
    return Material(
      color: ColorTokens.warningAmber.withOpacity(0.9),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: ColorTokens.navy950),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'بعض البيانات لا يمكن قراءتها بسبب اختلاف مفاتيح التشفير. جرب استعادة نسخة احتياطية محلية.',
                style: TextStyle(color: ColorTokens.navy950, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: _navigateToRestore,
              child: const Text('استعادة', style: TextStyle(color: ColorTokens.navy950, decoration: TextDecoration.underline)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: ColorTokens.navy950, size: 18),
              onPressed: () => InjectionContainer.syncStatusCubit.reset(),
            ),
          ],
        ),
      ),
    );
  }
}
