import 'package:flutter/material.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/income_source_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/management/asset_creation_wizard_page.dart';
import 'package:qayd/presentation/pages/management/expense_creation_wizard_page.dart';
import 'package:qayd/presentation/pages/management/income_source_type_sheet.dart';
import 'package:qayd/presentation/pages/management/income_stream_detail_page.dart';
import 'package:qayd/presentation/pages/management/profession_creation_wizard.dart';
import 'package:qayd/presentation/pages/management/widgets/income_stream_card.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

/// Unified page for managing all income streams (assets, professions, etc.)
/// and personal possessions.
///
/// Replaces the old [PersonalFlowManagementPage].
class IncomeStreamsPage extends StatefulWidget {
  const IncomeStreamsPage({super.key});

  @override
  State<IncomeStreamsPage> createState() => _IncomeStreamsPageState();
}

class _IncomeStreamsPageState extends State<IncomeStreamsPage> {
  String? _depreciableAssetsRootId;
  String? _profitableAssetsRootId;
  String? _personalRevenuesRootId;
  String? _personalExpensesRootId;
  // String? _personalExpensesRootName;
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
            switch (a.standardClassificationKind) {
              case 'fixedDepreciableAssets':
                _depreciableAssetsRootId = a.id;
              case 'fixedProfitableAssets':
                _profitableAssetsRootId = a.id;
              case 'personalRevenues':
                _personalRevenuesRootId = a.id;
              case 'personalExpenses':
                _personalExpensesRootId = a.id;
                // _personalExpensesRootName = a.name;
            }
          }
        }
        setState(() => _isLoadingRoots = false);
      },
    );
  }

  Future<void> _openAddWizard() async {
    final type = await showIncomeSourceTypeSheet(context);
    if (type == null || !mounted) return;

    bool? updated;
    switch (type) {
      case IncomeSourceType.investmentAsset:
        updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => AssetCreationWizardPage(
              depreciableAssetsRootId: _depreciableAssetsRootId,
              profitableAssetsRootId: _profitableAssetsRootId,
            ),
          ),
        );
      case IncomeSourceType.possession:
        updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => AssetCreationWizardPage(
              depreciableAssetsRootId: _depreciableAssetsRootId,
              profitableAssetsRootId: _profitableAssetsRootId,
            ),
          ),
        );
      case IncomeSourceType.profession:
        updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ProfessionCreationWizardPage(
              personalRevenuesRootId: _personalRevenuesRootId,
            ),
          ),
        );
      case IncomeSourceType.other:
        updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ProfessionCreationWizardPage(
              personalRevenuesRootId: _personalRevenuesRootId,
            ),
          ),
        );
    }

    if (updated == true && mounted) {
      setState(() {}); // Trigger rebuild to refresh lists
    }
  }

  Future<void> _openAddExpenseAccount() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExpenseCreationWizardPage(
          personalExpensesRootId: _personalExpensesRootId,
        ),
      ),
    );
    if (updated == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.extension<QaydCustomColors>()!.goldAccent;

    if (_isLoadingRoots) {
      return const QaydScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      child: QaydScaffold(
        appBar: QaydAppBar(
          title: AppStringsAr.incomeStreamsTitle,
          bottom: const TabBar(
            tabs: [
              Tab(text: AppStringsAr.incomeStreamsTabIncome),
              Tab(text: AppStringsAr.incomeStreamsTabPossessions),
              Tab(text: AppStringsAr.incomeStreamsTabExpenses),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Income Streams (investments + professions + other)
            _IncomeStreamsList(
              kinds: const [
                'fixedProfitableAssets',
                'personalRevenues',
              ],
              incomeSourceFilter: const [
                'investment_asset',
                'profession',
                'other',
              ],
              emptyText: AppStringsAr.incomeStreamsEmpty,
              emptyIcon: Icons.trending_up_rounded,
              key: const PageStorageKey('income_streams'),
            ),

            // Tab 2: Personal Possessions (depreciable assets)
            _IncomeStreamsList(
              kinds: const ['fixedDepreciableAssets'],
              incomeSourceFilter: const ['possession'],
              emptyText: AppStringsAr.possessionsEmpty,
              emptyIcon: Icons.inventory_2_outlined,
              key: const PageStorageKey('possessions'),
            ),

            // Tab 3: Expense Categories
            _IncomeStreamsList(
              kinds: const ['personalExpenses'],
              incomeSourceFilter: null,
              emptyText: AppStringsAr.expenseCategoriesEmpty,
              emptyIcon: Icons.receipt_long_outlined,
              key: const PageStorageKey('expense_categories'),
              onSeed: () async {
                final res = await InjectionContainer.seedExpenseAccountsUseCase();
                if (res.isSuccess) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                final isExpenseTab = tabController.index == 2;
                return FloatingActionButton.extended(
                  heroTag: 'fab_income_streams',
                  onPressed: isExpenseTab
                      ? _openAddExpenseAccount
                      : _openAddWizard,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isExpenseTab
                      ? AppStringsAr.incomeStreamsAddExpense
                      : AppStringsAr.incomeStreamsAddSource),
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Inner list widget ─────────────────────────────────────────────────────────

class _IncomeStreamsList extends StatefulWidget {
  const _IncomeStreamsList({
    super.key,
    required this.kinds,
    required this.incomeSourceFilter,
    required this.emptyText,
    required this.emptyIcon,
    this.onSeed,
  });

  final List<String> kinds;

  /// If non-null, only shows accounts whose `metadata['income_source_type']`
  /// matches one of these values.
  final List<String>? incomeSourceFilter;
  final String emptyText;
  final IconData emptyIcon;
  final VoidCallback? onSeed;

  @override
  State<_IncomeStreamsList> createState() => _IncomeStreamsListState();
}

class _IncomeStreamsListState extends State<_IncomeStreamsList> {
  bool _loading = true;
  List<AccountSummaryDto> _accounts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_IncomeStreamsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kinds != widget.kinds) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await InjectionContainer.listAccountsUseCase(
      const ListAccountsInput(activeOnly: false),
    );
    res.fold(
      (_) => setState(() => _loading = false),
      (data) {
        setState(() {
          _accounts = data.accounts.where((a) {
            final matchesKind =
                widget.kinds.contains(a.standardClassificationKind);
            final isChild = a.parentId != null;

            if (!matchesKind || !isChild) return false;

            // Apply income source type filter if specified
            if (widget.incomeSourceFilter != null) {
              final sourceType = a.metadata?['income_source_type'] as String?;
              // If no source type in metadata, include only if 'other' is in filter
              // or if the classification already implies the type
              if (sourceType != null) {
                return widget.incomeSourceFilter!.contains(sourceType);
              }
              // Legacy accounts without income_source_type: include based on classification
              return true;
            }

            return true;
          }).toList();
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.emptyIcon,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: SpacingTokens.md),
            QaydText(
              widget.emptyText,
              color: Theme.of(context).colorScheme.outline,
              textAlign: TextAlign.center,
            ),
            if (widget.onSeed != null) ...[
              const SizedBox(height: SpacingTokens.lg),
              FilledButton.tonalIcon(
                onPressed: widget.onSeed,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('توليد التصنيفات التلقائية'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(SpacingTokens.md),
        itemCount: _accounts.length,
        itemBuilder: (ctx, i) {
          final a = _accounts[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
            child: IncomeStreamCard(
              account: a,
              onTap: () async {
                await Navigator.of(context).push<void>(
                  QaydPageRoute.slideFromStart<void>(
                    builder: (ctx) => IncomeStreamDetailPage(summary: a),
                  ),
                );
                if (mounted) {
                  _load();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
