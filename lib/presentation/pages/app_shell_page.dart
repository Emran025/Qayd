import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/backup/restore_cubit.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/accounts/account_list_page.dart';
import 'package:qayd/presentation/pages/backup/restore_discovery_page.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_page.dart';
import 'package:qayd/presentation/pages/vouchers/tripartite_list_page.dart';
import 'package:qayd/presentation/pages/management/internal_management_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_page.dart';
import 'package:qayd/presentation/pages/accounts/account_statement_chat_page.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_cubit.dart';
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
  int _reportKeyId = 0;
  bool _showRestorePrompt = false;

  @override
  void initState() {
    super.initState();
    _checkEmptyDb();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    InjectionContainer.nativeNotificationService.onNotificationTap
        .listen((payload) {
      if (payload == null || !mounted) return;

      try {
        // Implementation note: In a real app, use a proper router or deep link handler.
        // For 'Qayd', we parse a simple string or JSON for navigation.
        if (payload.startsWith('voucher_chat:')) {
          final cpId = payload.split(':')[1];
          _navigateToChat(cpId);
        }
      } catch (e) {
        debugPrint('Error handling notification tap: $e');
      }
    });
  }

  void _navigateToChat(String cpId) {
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => BlocProvider(
          create: (_) => StatementChatCubit(
            listStatement: InjectionContainer.listAccountStatementChatUseCase,
            listAccounts: InjectionContainer.listAccountsUseCase,
            counterpartyAccountId: cpId,
            getCostCenterDetails:
                InjectionContainer.getCostCenterDetailsUseCase,
          )..load(),
          child: AccountStatementChatPage(counterpartyAccountId: cpId),
        ),
      ),
    );
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
      showDrawer: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: [
              VoucherListPage(isActive: _index == 0),
              TripartiteListPage(isActive: _index == 1),
              AccountListPage(isActive: _index == 2),
              TrialBalancePage(key: ValueKey('reports_$_reportKeyId')),
              InternalManagementPage(isActive: _index == 4),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  if (_showRestorePrompt) _buildRestoreBanner(context),
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
        onDestinationSelected: (i) {
          if (i == 3 && _index != 3) {
            _reportKeyId++;
          }
          setState(() => _index = i);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: gold),
            label: AppStrings.navVouchersTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon:
                Icon(Icons.swap_horizontal_circle_rounded, color: gold),
            label: AppStrings.navTripartiteTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon:
                Icon(Icons.account_balance_wallet_rounded, color: gold),
            label: AppStrings.navAccountsTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart_rounded, color: gold),
            label: AppStrings.navReportsTab,
          ),
          NavigationDestination(
            icon: Icon(Icons.business_center_outlined),
            selectedIcon: Icon(Icons.business_center_rounded, color: gold),
            label: AppStrings.navManagementTab,
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
            Icon(Icons.restore_rounded, color: Colors.white),
            SizedBox(width: 12),
             Expanded(
              child: Text(
                AppStrings.weFoundALocal,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _navigateToRestore,
              child: Text(AppStrings.restoreNow,
                  style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline)),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 18),
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
            Icon(Icons.lock_reset_rounded, color: ColorTokens.navy950),
            SizedBox(width: 12),
             Expanded(
              child: Text(
                AppStrings.someDataCannotBe,
                style: TextStyle(
                    color: ColorTokens.navy950,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: _navigateToRestore,
              child: Text(AppStrings.restoration,
                  style: TextStyle(
                      color: ColorTokens.navy950,
                      decoration: TextDecoration.underline)),
            ),
            IconButton(
              icon:
                  Icon(Icons.close, color: ColorTokens.navy950, size: 18),
              onPressed: () => InjectionContainer.syncStatusCubit.reset(),
            ),
          ],
        ),
      ),
    );
  }
}
