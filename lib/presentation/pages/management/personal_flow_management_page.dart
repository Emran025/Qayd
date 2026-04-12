import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/management/asset_creation_wizard_page.dart';
import 'package:qayd/presentation/pages/management/widgets/personal_accounts_list_view.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class PersonalFlowManagementPage extends StatefulWidget {
  const PersonalFlowManagementPage({super.key});

  @override
  State<PersonalFlowManagementPage> createState() =>
      _PersonalFlowManagementPageState();
}

class _PersonalFlowManagementPageState
    extends State<PersonalFlowManagementPage> {
  String? _depreciableAssetsRootId;
  String? _profitableAssetsRootId;
  bool _isLoadingRoots = true;

  @override
  void initState() {
    super.initState();
    _loadRoots();
  }

  Future<void> _loadRoots() async {
    final result = await InjectionContainer.listAccountsUseCase(
      const ListAccountsInput(activeOnly: false),
    );
    result.fold(
      (_) => setState(() => _isLoadingRoots = false),
      (out) {
        for (final a in out.accounts) {
          if (a.isRoot) {
            if (a.standardClassificationKind == 'fixedDepreciableAssets') {
              _depreciableAssetsRootId = a.id;
            } else if (a.standardClassificationKind ==
                'fixedProfitableAssets') {
              _profitableAssetsRootId = a.id;
            }
          }
        }
        setState(() => _isLoadingRoots = false);
      },
    );
  }

  Future<void> _openAssetWizard() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AssetCreationWizardPage(
          depreciableAssetsRootId: _depreciableAssetsRootId,
          profitableAssetsRootId: _profitableAssetsRootId,
        ),
      ),
    );
    if (updated == true) {
      setState(() {}); // Trigger rebuild to refresh lists
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.extension<QaydCustomColors>()!.goldAccent;

    return DefaultTabController(
      length: 2,
      child: QaydScaffold(
        appBar: QaydAppBar(
          title: AppStringsAr.managementTabPersonalFlowAccounts,
          bottom: const TabBar(
            tabs: [
              Tab(text: AppStringsAr.managementTabAssets),
              Tab(text: AppStringsAr.managementTabOutflowSources),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: _isLoadingRoots
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Assets (Copy from AssetsManagementPage)
                  PersonalAccountsListView(
                    kinds: const [
                      'fixedDepreciableAssets',
                      'fixedProfitableAssets'
                    ],
                    emptyText: AppStringsAr.managementAssetsEmpty,
                    showAssetDetails: true,
                    key: const PageStorageKey('assets_list'),
                  ),

                  // Tab 2: Outflow Sources (Expenses)
                  PersonalAccountsListView(
                    kinds: const ['personalExpenses'],
                    emptyText: AppStringsAr.managementExpensesEmpty,
                    showAssetDetails: false,
                    key: const PageStorageKey('expenses_list'),
                  ),
                ],
              ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            // Since DefaultTabController doesn't easily notify FAB on build,
            // we use an AnimatedBuilder or just show the Asset FAB if we want to simplify.
            // But the user asked for Assets page "as is" which has the FAB.
            // For the second tab, maybe we don't need a FAB yet or it could be "Add Expense Category".

            return AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                if (tabController.index == 0) {
                  return FloatingActionButton.extended(
                    onPressed: _openAssetWizard,
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text(AppStringsAr.managementAddAssetFab),
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                  );
                }
                // Possibly another FAB for tab 2 if needed
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}
