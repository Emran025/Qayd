import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/vouchers/dtos/advanced_filter_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/atomic/qayd_empty_state.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/management/internal_voucher_create_page.dart';
import 'package:qayd/presentation/pages/management/widgets/internal_voucher_tile.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_detail_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_state.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_suggestions_cubit.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class InternalManagementPage extends StatefulWidget {
  const InternalManagementPage({super.key, this.isActive = true});
  final bool isActive;

  @override
  State<InternalManagementPage> createState() => _InternalManagementPageState();
}

class _InternalManagementPageState extends State<InternalManagementPage> {
  final Map<String, String> _accountClassifications = {};
  bool _isLoadingRoots = true;
  late final VoucherListCubit _listCubit;

  @override
  void initState() {
    super.initState();
    _listCubit = VoucherListCubit(
      InjectionContainer.listVouchersUseCase,
      InjectionContainer.notificationMessageRepository,
    )..setAdvancedFilter(const AdvancedFilterInput(isInternalOnly: true));
    _loadRoots();
  }

  @override
  void didUpdateWidget(InternalManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _listCubit.load();
    }
  }

  @override
  void dispose() {
    _listCubit.close();
    super.dispose();
  }

  Future<void> _loadRoots() async {
    final result = await InjectionContainer.listAccountsUseCase(
      const ListAccountsInput(activeOnly: false),
    );
    result.fold(
      (_) => setState(() => _isLoadingRoots = false),
      (out) {
        for (final a in out.accounts) {
          _accountClassifications[a.id] = a.standardClassificationKind ?? '';
        }
        setState(() => _isLoadingRoots = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRoots) {
      return const QaydScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: _listCubit,
      child: _InternalManagementView(
        accountClassifications: _accountClassifications,
      ),
    );
  }
}

class _InternalManagementView extends StatefulWidget {
  const _InternalManagementView({
    required this.accountClassifications,
  });

  final Map<String, String> accountClassifications;

  @override
  State<_InternalManagementView> createState() =>
      _InternalManagementViewState();
}

class _InternalManagementViewState extends State<_InternalManagementView> {
  final _searchController = TextEditingController();
  String _flowFilter = 'all'; // 'all', 'revenues', 'expenses'

  Future<void> _openCreate(BuildContext context) async {
    final listCubit = context.read<VoucherListCubit>();
    // Logic for creation based on current visual filter
    VoucherType? type =
        _flowFilter == 'revenues' ? VoucherType.receipt : VoucherType.payment;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => VoucherCreateCubit(
                InjectionContainer.createVoucherUseCase,
                InjectionContainer.createTripartiteTransferUseCase,
              ),
            ),
            BlocProvider(
              create: (_) => VoucherSuggestionsCubit(
                InjectionContainer.getAutoSuggestionsUseCase,
                InjectionContainer.markNotificationMessageProcessedUseCase,
              ),
            ),
          ],
          child: InternalVoucherCreatePage(initialType: type),
        ),
      ),
    );

    if (mounted) listCubit.load();
  }

  Future<void> _openDetail(BuildContext context, String voucherId) async {
    final listCubit = context.read<VoucherListCubit>();
    await VoucherDetailPage.show(context, voucherId);
    listCubit.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gold = theme.extension<QaydCustomColors>()!.goldAccent;

    return QaydScaffold(
      appBar: QaydAppBar(
        showNotifications: true,
        title: AppStrings.managementTabFundFlows,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: Icon(Icons.add_rounded),
        label: Text(AppStrings.managementAddFlowFab),
        backgroundColor: gold,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<VoucherListCubit, VoucherListState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildControlPanel(context, state, scheme, gold),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(SpacingTokens.md),
                child: Column(
                  children: [
                    QaydTextField(
                      controller: _searchController,
                      hint: AppStrings.managementSearchVouchersHint,
                      prefixIcon: Icon(Icons.search_rounded),
                      onChanged: (v) =>
                          context.read<VoucherListCubit>().setSearchText(v),
                    ),
                    SizedBox(height: SpacingTokens.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text(AppStrings.filterNatureAll),
                            selected: _flowFilter == 'all',
                            onSelected: (_) =>
                                setState(() => _flowFilter = 'all'),
                          ),
                          SizedBox(width: SpacingTokens.sm),
                          FilterChip(
                            label: Text(
                                AppStrings.managementLabelExpenses),
                            selected: _flowFilter == 'expenses',
                            onSelected: (_) =>
                                setState(() => _flowFilter = 'expenses'),
                          ),
                          SizedBox(width: SpacingTokens.sm),
                          FilterChip(
                            label: Text(
                                AppStrings.managementLabelRevenues),
                            selected: _flowFilter == 'revenues',
                            onSelected: (_) =>
                                setState(() => _flowFilter = 'revenues'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: state is VoucherListLoading
                    ? Center(child: CircularProgressIndicator())
                    : _buildList(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, VoucherListState state) {
    if (state is! VoucherListReady) return const SizedBox.shrink();

    // Filter list locally based on _flowFilter
    final list = state.vouchers.where((v) {
      if (_flowFilter == 'expenses') return v.typeCode == 'payment';
      if (_flowFilter == 'revenues') return v.typeCode == 'receipt';
      return true;
    }).toList();

    if (list.isEmpty) {
      final isSearching = state.searchQuery.isNotEmpty;
      return QaydEmptyState(
        icon: isSearching
            ? Icons.search_off_rounded
            : Icons.account_balance_wallet_outlined,
        title: isSearching
            ? AppStrings.managementSearchNoResults
            : AppStrings.vouchersEmpty,
        description: isSearching
            ? AppStrings.trySearchingWithOther1
            : AppStrings.youHaveNotAdded1,
      );
    }
    return ListView.builder(
      padding:
          const EdgeInsets.fromLTRB(SpacingTokens.md, 0, SpacingTokens.md, 80),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final v = list[i];
        return InternalVoucherTile(
          dto: v,
          onTap: () => _openDetail(context, v.id),
        );
      },
    );
  }

  Widget _buildControlPanel(BuildContext context, VoucherListState state,
      ColorScheme scheme, Color gold) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;

    // Multi-currency maps: Symbol -> Amount
    final Map<String, double> expensesByCurrency = {};
    final Map<String, double> revenuesByCurrency = {};

    if (state is VoucherListReady) {
      for (final v in state.vouchers) {
        final classification =
            widget.accountClassifications[v.counterpartyAccountId];
        // Skip debt settlements
        if (classification == 'payables' || classification == 'receivables') {
          continue;
        }

        final symbol = v.currencySymbol;
        final amount = v.amountMinorUnits / 100;

        if (v.typeCode == 'payment') {
          expensesByCurrency[symbol] =
              (expensesByCurrency[symbol] ?? 0) + amount;
        } else if (v.typeCode == 'receipt') {
          revenuesByCurrency[symbol] =
              (revenuesByCurrency[symbol] ?? 0) + amount;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(color: scheme.surface),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatCard(
            label: AppStrings.managementLabelExpenses,
            balances: expensesByCurrency,
            color: custom.debit,
            icon: Icons.north_east_rounded,
          ),
          SizedBox(width: SpacingTokens.md),
          _StatCard(
            label: AppStrings.managementLabelRevenues,
            balances: revenuesByCurrency,
            color: custom.credit,
            icon: Icons.south_west_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.balances,
    required this.color,
    required this.icon,
  });

  final String label;
  final Map<String, double> balances;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Default if empty
    final displayBalances = balances.isEmpty ? {'': 0.0} : balances;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 14, color: color),
              SizedBox(width: 4),
              QaydText(label,
                  slot: QaydTextStyleSlot.labelSmall,
                  color: scheme.onSurfaceVariant),
            ]),
            SizedBox(height: SpacingTokens.sm),
            ...displayBalances.entries.map((e) {
              final amountStr = e.value.toStringAsFixed(2);
              final symbol = e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: QaydText(
                        amountStr,
                        slot: QaydTextStyleSlot.titleMedium,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(width: 4),
                    QaydText(
                      symbol,
                      slot: QaydTextStyleSlot.labelSmall,
                      color: color,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
