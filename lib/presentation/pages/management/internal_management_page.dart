import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/vouchers/dtos/advanced_filter_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/management/internal_voucher_create_page.dart';
import 'package:qayd/presentation/pages/management/widgets/internal_voucher_tile.dart';
import 'package:qayd/presentation/pages/management/widgets/personal_accounts_list_view.dart';
import 'package:qayd/presentation/pages/accounts/account_create_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/pages/accounts/account_create_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_detail_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_state.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_suggestions_cubit.dart';
import 'package:qayd/presentation/pages/accruals/accrual_list_page.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/widgets/qayd_scaffold.dart';

class InternalManagementPage extends StatefulWidget {
  const InternalManagementPage({super.key});

  @override
  State<InternalManagementPage> createState() => _InternalManagementPageState();
}

class _InternalManagementPageState extends State<InternalManagementPage> {
  String? _fundRootId;
  String? _expensesRootId;
  String? _revenuesRootId;
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
            if (a.standardClassificationKind == 'liquidAssets') {
              _fundRootId = a.id;
            } else if (a.standardClassificationKind == 'personalExpenses') {
              _expensesRootId = a.id;
            } else if (a.standardClassificationKind == 'personalRevenues') {
              _revenuesRootId = a.id;
            } else if (a.standardClassificationKind ==
                'fixedDepreciableAssets') {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRoots) {
      return const QaydScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filter = const AdvancedFilterInput(
      isInternalOnly: true,
    );

    return BlocProvider(
      create: (_) => VoucherListCubit(
        InjectionContainer.listVouchersUseCase,
        InjectionContainer.notificationMessageRepository,
      )..setAdvancedFilter(filter),
      child: _InternalManagementView(
        fundRootId: _fundRootId,
        expensesRootId: _expensesRootId,
        revenuesRootId: _revenuesRootId,
        depreciableAssetsRootId: _depreciableAssetsRootId,
        profitableAssetsRootId: _profitableAssetsRootId,
      ),
    );
  }
}

class _InternalManagementView extends StatefulWidget {
  const _InternalManagementView({
    required this.fundRootId,
    required this.expensesRootId,
    required this.revenuesRootId,
    this.depreciableAssetsRootId,
    this.profitableAssetsRootId,
  });

  final String? fundRootId;
  final String? expensesRootId;
  final String? revenuesRootId;
  final String? depreciableAssetsRootId;
  final String? profitableAssetsRootId;

  @override
  State<_InternalManagementView> createState() =>
      _InternalManagementViewState();
}

class _InternalManagementViewState extends State<_InternalManagementView>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  Future<void> _openCreate(BuildContext context) async {
    final listCubit = context.read<VoucherListCubit>();
    if (_tabController.index == 0 ||
        _tabController.index == 2 ||
        _tabController.index == 3) {
      VoucherType? type;
      if (_tabController.index == 2) type = VoucherType.receipt;
      if (_tabController.index == 3) type = VoucherType.payment;

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
    } else {
      String? parentId;
      String? parentKind;

      if (_tabController.index == 1) {
        // Assets are typically added under depreciable assets by default here
        parentId = widget.depreciableAssetsRootId;
        parentKind = 'fixedDepreciableAssets';
      }

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BlocProvider(
              create: (_) => AccountCreateCubit(
                InjectionContainer.createAccountUseCase,
              ),
              child: AccountCreatePage(
                forcedIsChild: true,
                parentAccountId: parentId,
                parentStandardKind: parentKind,
                allowedStandardKinds: _tabController.index == 1
                    ? const [
                        StandardAccountClassificationKind
                            .fixedDepreciableAssets,
                        StandardAccountClassificationKind.fixedProfitableAssets,
                      ]
                    : null,
              ),
            ),
          ),
        ),
      );
    }
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
    _tabController.dispose();
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
        title: AppStringsAr.managementTitle,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'السجل المالي'),
            Tab(text: 'الأصول والممتلكات'),
            Tab(text: 'إيرادات الصندوق'),
            Tab(text: 'مصاريف الصندوق'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<VoucherListCubit>().load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: Icon(_tabController.index == 0
            ? Icons.add_rounded
            : Icons.plus_one_rounded),
        label: Text(_getFabLabel()),
        backgroundColor: gold,
        foregroundColor: Colors.black,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Financial Records
          BlocBuilder<VoucherListCubit, VoucherListState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildControlPanel(context, state, scheme, gold),
                  const Divider(height: 1),
                  _buildFilterChips(context, state, gold),
                  Expanded(
                    child: state is VoucherListLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildList(context, state),
                  ),
                ],
              );
            },
          ),
          // ── Tab 2: Assets
          const PersonalAccountsListView(
            kinds: ['fixedDepreciableAssets', 'fixedProfitableAssets'],
            emptyText: 'لا تملك أي أصول مسجلة حالياً.',
            showAssetDetails: true,
          ),
          // ── Tab 3: Revenues
          const PersonalAccountsListView(
            kinds: ['personalRevenues'],
            emptyText: 'لا تملك أي إيرادات داخلية مسجلة حالياً.',
          ),
          // ── Tab 4: Expenses
          const PersonalAccountsListView(
            kinds: ['personalExpenses'],
            emptyText: 'لا تملك أي مصاريف داخلية مسجلة حالياً.',
          ),
        ],
      ),
    );
  }

  String _getFabLabel() {
    switch (_tabController.index) {
      case 0:
        return AppStringsAr.addInternalVoucherFab;
      case 1:
        return 'إضافة أصل جديد';
      case 2:
        return 'تسجيل إيراد داخلي';
      case 3:
        return 'تسجيل مصروف داخلي';
      default:
        return AppStringsAr.addInternalVoucherFab;
    }
  }

  Widget _buildControlPanel(BuildContext context, VoucherListState state,
      ColorScheme scheme, Color gold) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    double totalExpenses = 0;
    double totalRevenues = 0;

    if (state is VoucherListReady) {
      for (final v in state.vouchers) {
        if (v.typeCode == 'payment') totalExpenses += v.amountMinorUnits / 100;
        if (v.typeCode == 'receipt') totalRevenues += v.amountMinorUnits / 100;
      }
    }

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: scheme.surface,
      ),
      child: Column(
        children: [
          QaydTextField(
            controller: _searchController,
            hint: 'ابحث في السندات الداخلية...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      context.read<VoucherListCubit>().clearSearch();
                    },
                  )
                : null,
            onChanged: (v) => context.read<VoucherListCubit>().setSearchText(v),
          ),
          const SizedBox(height: SpacingTokens.md),
          Row(
            children: [
              _StatCard(
                label: 'المصروفات',
                amount: totalExpenses,
                color: custom.debit,
                icon: Icons.north_east_rounded,
              ),
              const SizedBox(width: SpacingTokens.md),
              _StatCard(
                label: 'الإيرادات',
                amount: totalRevenues,
                color: custom.credit,
                icon: Icons.south_west_rounded,
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccrualListPage()),
            ),
            borderRadius: BorderRadius.circular(RadiusTokens.lg),
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    ColorTokens.navy800,
                    ColorTokens.navy700,
                  ],
                ),
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_repeat_rounded,
                      color: ColorTokens.warningAmber),
                  const SizedBox(width: SpacingTokens.md),
                  const Expanded(
                    child: Text(
                      'إدارة الالتزامات الدورية',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded, color: Colors.white54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
      BuildContext context, VoucherListState state, Color gold) {
    if (state is! VoucherListReady) return const SizedBox.shrink();
    final currentType = state.advancedFilter.type;
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
        children: [
          FilterChip(
            label: const Text('الكل'),
            selected: currentType == null,
            onSelected: (_) =>
                context.read<VoucherListCubit>().patchAdvancedFilter(
                      (f) => f.copyWith(type: null),
                    ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          FilterChip(
            label: const Text('المصروفات'),
            selected: currentType == VoucherType.payment,
            onSelected: (_) =>
                context.read<VoucherListCubit>().patchAdvancedFilter(
                      (f) => f.copyWith(type: VoucherType.payment),
                    ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          FilterChip(
            label: const Text('الإيرادات'),
            selected: currentType == VoucherType.receipt,
            onSelected: (_) =>
                context.read<VoucherListCubit>().patchAdvancedFilter(
                      (f) => f.copyWith(type: VoucherType.receipt),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, VoucherListState state) {
    if (state is! VoucherListReady) return const SizedBox.shrink();
    final list = state.vouchers;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: SpacingTokens.md),
            QaydText(
              state.searchQuery.isNotEmpty
                  ? 'لا توجد نتائج لبحثك'
                  : AppStringsAr.vouchersEmpty,
              slot: QaydTextStyleSlot.bodyLarge,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
              const SizedBox(width: 4),
              QaydText(label,
                  slot: QaydTextStyleSlot.labelSmall,
                  color: scheme.onSurfaceVariant),
            ]),
            const SizedBox(height: 4),
            QaydText(amount.toStringAsFixed(2),
                slot: QaydTextStyleSlot.titleMedium),
          ],
        ),
      ),
    );
  }
}
