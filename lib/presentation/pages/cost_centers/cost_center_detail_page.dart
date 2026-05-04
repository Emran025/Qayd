import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_floating_action_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/statement_chat_filter_input.dart';
import 'package:qayd/application/cost_centers/dtos/center_voucher_summary.dart';
import 'package:qayd/application/cost_centers/dtos/cost_center_details_dto.dart';
import 'package:qayd/application/cost_centers/get_cost_center_details_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/accounts/account_statement_chat_page.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_cubit.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_create_page.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_extensions.dart';
import 'package:qayd/presentation/pages/cost_centers/widgets/analytics_section.dart';
import 'package:qayd/presentation/pages/cost_centers/widgets/cost_center_header_widget.dart';
import 'package:qayd/presentation/pages/cost_centers/widgets/filter_action_bar.dart';
import 'package:qayd/presentation/pages/cost_centers/widgets/financial_metrics_grid.dart';
import 'package:qayd/presentation/pages/cost_centers/widgets/transaction_history_tile.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Cubit (unchanged — pure data logic)
// ═══════════════════════════════════════════════════════════════════════════════

sealed class _State {}

final class _Loading extends _State {}

final class _Ready extends _State {
  _Ready(this.dto);
  final CostCenterDetailsDto dto;
}

final class _Failure extends _State {
  _Failure(this.failure);
  final Failure failure;
}

final class _Cubit extends Cubit<_State> {
  _Cubit(this._useCase, this.centerId) : super(_Loading());

  final GetCostCenterDetailsUseCase _useCase;
  final String centerId;

  Future<void> load() async {
    emit(_Loading());
    final res = await _useCase(centerId);
    res.fold((f) => emit(_Failure(f)), (dto) => emit(_Ready(dto)));
  }

  Future<void> toggleStatus() async {
    final s = state;
    if (s is! _Ready) return;
    final center = s.dto.center;
    final res = center.isActive
        ? await InjectionContainer.suspendCostCenterUseCase(center.id)
        : await InjectionContainer.activateCostCenterUseCase(center.id);
    res.fold((_) {}, (_) => load());
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Entry point
// ═══════════════════════════════════════════════════════════════════════════════

class CostCenterDetailPage extends StatelessWidget {
  const CostCenterDetailPage({super.key, required this.centerId});
  final String centerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _Cubit(
        InjectionContainer.getCostCenterDetailsUseCase,
        centerId,
      )..load(),
      child: const _StateRouter(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// State router — Loading / Error / Ready
// ═══════════════════════════════════════════════════════════════════════════════

class _StateRouter extends StatelessWidget {
  const _StateRouter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<_Cubit, _State>(
      builder: (context, state) => switch (state) {
        _Loading() => Scaffold(
            body: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        _Failure(:final failure) => _ErrorView(failure: failure),
        _Ready(:final dto) => _DashboardView(dto: dto),
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.failure});
  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.errorTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 44, color: scheme.error),
              SizedBox(height: SpacingTokens.md),
              Text(
                failure.messageAr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: SpacingTokens.lg),
              FilledButton.icon(
                onPressed: () => context.read<_Cubit>().load(),
                icon: Icon(Icons.refresh_rounded, size: 18),
                label: Text(AppStrings.retryAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Dashboard — The premium financial dashboard
// ═══════════════════════════════════════════════════════════════════════════════

class _DashboardView extends StatefulWidget {
  const _DashboardView({required this.dto});
  final CostCenterDetailsDto dto;

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with SingleTickerProviderStateMixin {
  String? _activeDimId;
  late AnimationController _bodyEntry;
  late Animation<double> _bodyFade;

  CostCenterDetailsDto get dto => widget.dto;
  bool get _isProfit => dto.center.type == CostCenterType.profit;
  Color get _typeColor => Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    _bodyEntry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bodyFade = CurvedAnimation(parent: _bodyEntry, curve: Curves.easeOut);
    _bodyEntry.forward();
  }

  @override
  void dispose() {
    _bodyEntry.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // final custom = Theme.of(context).extension<QaydCustomColors>()!;

    final filtered = _activeDimId == null
        ? dto.recentVouchers
        : dto.recentVouchers
            .where((v) => v.dimensionIds.contains(_activeDimId))
            .toList();

    return Scaffold(
      
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ════════════════════════════════════════════════════════
          // 1. Hero App Bar — the visual anchor
          // ════════════════════════════════════════════════════════
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            leading: const BackButton(color: Colors.white),
            iconTheme: const IconThemeData(color: Colors.white),
            
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [_actionsMenu(context)],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [StretchMode.zoomBackground],
              background: CostCenterHeaderWidget(
                center: dto.center,
                dto: dto,
                typeColor: _typeColor,
                isProfit: _isProfit,
              ),
            ),
          ),

          // ════════════════════════════════════════════════════════
          // 2. Body — all scrollable content
          // ════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _bodyFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SpacingTokens.md,
                  SpacingTokens.md,
                  SpacingTokens.md,
                  100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Metrics Strip ──────────────────────────────
                    FinancialMetricsGrid(
                      dto: dto,
                      typeColor: _typeColor,
                      isProfit: _isProfit,
                    ),
                    SizedBox(height: SpacingTokens.md + 4),

                    // ── Analytics (trend + donut + gauge) ──────────
                    AnalyticsSection(
                      dto: dto,
                      typeColor: _typeColor,
                      isProfit: _isProfit,
                      activeDimId: _activeDimId,
                      onDimTap: _toggleDim,
                    ),

                    // ── Dimensions list ───────────────────────
                    if (dto.dimensions.isNotEmpty)
                      _DimensionsList(
                        centerName: dto.center.name,
                        dims: dto.dimensions,
                        getCategoryColor: _getCategoryColor,
                      ),

                    // ── Filter bar ────────────────────────────────
                    FilterActionBar(
                      breakdownItems: dto.dimensionBreakdown,
                      activeDimId: _activeDimId,
                      typeColor: _typeColor,
                      onDimTap: _toggleDim,
                      onClearFilter: () => setState(() => _activeDimId = null),
                    ),

                    // ── Activity Feed ─────────────────────────────
                    _ActivitySection(
                      filtered: filtered,
                      typeColor: _typeColor,
                      onViewMore: () => _openChatView(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _toggleDim(String id) =>
      setState(() => _activeDimId = _activeDimId == id ? null : id);

  Color _getCategoryColor(CostCenterDimensionCategory category) {
    if (category == CostCenterDimensionCategory.incomeAndWork) {
      return ColorTokens.emerald600;
    }
    if (category == CostCenterDimensionCategory.housingAndLiving) {
      return ColorTokens.debitBlue;
    }
    if (category == CostCenterDimensionCategory.nutritionAndConsumption) {
      return Colors.orange;
    }
    if (category == CostCenterDimensionCategory.transportation) {
      return Colors.blueGrey;
    }
    if (category == CostCenterDimensionCategory.healthAndPersonalCare) {
      return Colors.redAccent;
    }
    if (category == CostCenterDimensionCategory.educationAndDevelopment) {
      return Colors.indigo;
    }
    if (category == CostCenterDimensionCategory.familyAndDependents) {
      return Colors.teal;
    }
    if (category == CostCenterDimensionCategory.obligationsAndDebts) {
      return Colors.deepOrange;
    }
    if (category == CostCenterDimensionCategory.investmentsAndProjects) {
      return ColorTokens.warningAmber;
    }
    if (category == CostCenterDimensionCategory.savingsAndReserves) {
      return Colors.purple;
    }
    if (category == CostCenterDimensionCategory.entertainmentAndLifestyle) {
      return Colors.pink;
    }
    return _typeColor;
  }

  // ── FAB ────────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return QaydFloatingActionButton.extended(
      heroTag: 'cost_center_fab',
      onPressed: () => _openChatView(context),
      
      
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
      ),
      icon: Icon(
        _isProfit
            ? Icons.add_circle_outline_rounded
            : Icons.remove_circle_outline_rounded,
        size: 20,
      ),
      label: Text(
        _isProfit
            ? AppStrings.costCenterQuickReceiveAction
            : AppStrings.costCenterQuickPayAction,
      ),
    );
  }

  // ── Actions Menu ──────────────────────────────────────────────────────────

  Widget _actionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      iconColor: Colors.white,
      onSelected: (val) {
        if (val == 'status') {
          context.read<_Cubit>().toggleStatus();
        } else if (val == 'edit') {
          _openEditPage(context);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text(AppStrings.costCenterEditAction),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        PopupMenuItem(
          value: 'status',
          child: ListTile(
            leading: Icon(dto.center.isActive
                ? Icons.pause_circle_outline_rounded
                : Icons.play_circle_outline_rounded),
            title: Text(dto.center.isActive
                ? AppStrings.costCenterSuspendAction
                : AppStrings.costCenterActivateAction),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _openChatView(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => BlocProvider(
          create: (_) => StatementChatCubit(
            listStatement: InjectionContainer.listAccountStatementChatUseCase,
            listAccounts: InjectionContainer.listAccountsUseCase,
            getCostCenterDetails:
                InjectionContainer.getCostCenterDetailsUseCase,
            counterpartyAccountId: dto.center.id,
            initialCounterpartyName: dto.center.name,
            initialFilter: StatementChatFilterInput(costCenterId: dto.center.id),
          )..load(),
          child: AccountStatementChatPage(counterpartyAccountId: dto.center.id),
        ),
      ),
    );
  }

  Future<void> _openEditPage(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => CostCenterCreatePage(
          initialCostCenter: dto.center,
          onCreated: () {},
        ),
      ),
    );
    if (updated == true && context.mounted) {
      context.read<_Cubit>().load();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Activity Feed Section
// ═══════════════════════════════════════════════════════════════════════════════

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.filtered,
    required this.typeColor,
    required this.onViewMore,
  });

  final List<CenterVoucherSummary> filtered;
  final Color typeColor;
  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section label ─────────────────────────────────────────
        Text(
          AppStrings.costCenterActivitySection,
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: SpacingTokens.md),

        // ── Timeline ──────────────────────────────────────────────
        if (filtered.isEmpty)
          _EmptyState()
        else
          TransactionHistoryList(vouchers: filtered),

        SizedBox(height: SpacingTokens.md),

        // ── View More ─────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: onViewMore,
          icon: Icon(Icons.forum_outlined, size: 16),
          label: Text(AppStrings.costCenterViewMoreVouchers),
          style: OutlinedButton.styleFrom(
            
            side: BorderSide(color: typeColor.withValues(alpha: 0.3)),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.md),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xl),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 32,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.15),
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            AppStrings.costCenterNoRecentVouchers,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Dimensions Section
// ═══════════════════════════════════════════════════════════════════════════════

class _DimensionsList extends StatelessWidget {
  const _DimensionsList({
    required this.centerName,
    required this.dims,
    required this.getCategoryColor,
  });

  final String centerName;
  final List<CostCenterDimension> dims;
  final Color Function(CostCenterDimensionCategory) getCategoryColor;

  @override
  Widget build(BuildContext context) {
    if (dims.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(
          top: SpacingTokens.md + 4, bottom: SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.costCenterDimensionsTitle(centerName),
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: SpacingTokens.sm),
          Wrap(
            spacing: SpacingTokens.xs,
            runSpacing: SpacingTokens.xs,
            children: dims.map((d) {
              final color = getCategoryColor(d.category);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  border: Border.all(
                    color: color.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(d.category.icon, size: 12, color: color),
                    SizedBox(width: 4),
                    Text(
                      d.name,
                      style: tt.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
