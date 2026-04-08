import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/vouchers/dtos/advanced_filter_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/components/inputs/qayd_text_field.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/management/internal_voucher_create_page.dart';
import 'package:qayd/presentation/pages/management/widgets/internal_voucher_tile.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_detail_page.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_state.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_suggestions_cubit.dart';
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

    final filter = AdvancedFilterInput(
      involvedRootAccountId: _fundRootId,
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
      ),
    );
  }
}

class _InternalManagementView extends StatefulWidget {
  const _InternalManagementView({
    required this.fundRootId,
    required this.expensesRootId,
    required this.revenuesRootId,
  });

  final String? fundRootId;
  final String? expensesRootId;
  final String? revenuesRootId;

  @override
  State<_InternalManagementView> createState() =>
      _InternalManagementViewState();
}

class _InternalManagementViewState extends State<_InternalManagementView> {
  final _searchController = TextEditingController();

  Future<void> _openCreate(BuildContext context) async {
    final listCubit = context.read<VoucherListCubit>();
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
          child: const InternalVoucherCreatePage(),
        ),
      ),
    );
    listCubit.load();
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: AppStringsAr.managementTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<VoucherListCubit>().load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(AppStringsAr.addInternalVoucherFab),
        backgroundColor: gold,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<VoucherListCubit, VoucherListState>(
        builder: (context, state) {
          return Column(
            children: [
              // ── Search & Stats Section ───────────────────────────────────
              _buildControlPanel(context, state, scheme, gold),

              const Divider(height: 1),

              // ── Filter Chips ─────────────────────────────────────────────
              _buildFilterChips(context, state, gold),

              // ── List Section ─────────────────────────────────────────────
              Expanded(
                child: state is VoucherListLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildList(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, VoucherListState state,
      ColorScheme scheme, Color gold) {
    final custom = theme.extension<QaydCustomColors>()!;
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
          // Search Field
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
          // KPI Summary
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

  ThemeData get theme => Theme.of(context);
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
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm + 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                QaydText(
                  label,
                  slot: QaydTextStyleSlot.labelSmall,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 4),
            QaydText(
              amount.toStringAsFixed(2),
              slot: QaydTextStyleSlot.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
