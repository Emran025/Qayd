import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/cost_centers/dtos/cost_center_details_dto.dart';
import 'package:qayd/application/cost_centers/get_cost_center_details_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/accounts/account_statement_chat_page.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_cubit.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_create_page.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_dashboard_widgets.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_extensions.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

// ── Cubit ─────────────────────────────────────────────────────────────────

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

// ── Page ──────────────────────────────────────────────────────────────────

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
      child: const _PageScaffold(),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<_Cubit, _State>(
      builder: (context, state) => switch (state) {
        _Loading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        _Failure(:final failure) => Scaffold(
            appBar: AppBar(title: Text(AppStringsAr.errorTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.messageAr, textAlign: TextAlign.center),
                    const SizedBox(height: SpacingTokens.md),
                    FilledButton(
                      onPressed: () => context.read<_Cubit>().load(),
                      child: Text(AppStringsAr.retryAction),
                    ),
                  ],
                ),
              ),
            ),
          ),
        _Ready(:final dto) => _Dashboard(dto: dto),
      },
    );
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────

class _Dashboard extends StatefulWidget {
  const _Dashboard({required this.dto});
  final CostCenterDetailsDto dto;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  String? _activeDimId; // null = show all

  CostCenterDetailsDto get dto => widget.dto;

  bool get _isProfit => dto.center.type == CostCenterType.profit;

  Color get _typeColor =>
      _isProfit ? ColorTokens.emerald600 : ColorTokens.debitBlue;

  Map<CostCenterDimensionCategory, List<CostCenterDimension>> get _groupedDims {
    final map = <CostCenterDimensionCategory, List<CostCenterDimension>>{};
    for (final dim in dto.dimensions) {
      map.putIfAbsent(dim.category, () => []).add(dim);
    }
    return map;
  }

  Color _getCategoryColor(CostCenterDimensionCategory category) {
    return switch (category) {
      CostCenterDimensionCategory.incomeAndWork => ColorTokens.emerald600,
      CostCenterDimensionCategory.housingAndLiving => ColorTokens.debitBlue,
      CostCenterDimensionCategory.nutritionAndConsumption => Colors.orange,
      CostCenterDimensionCategory.transportation => Colors.blueGrey,
      CostCenterDimensionCategory.healthAndPersonalCare => Colors.redAccent,
      CostCenterDimensionCategory.educationAndDevelopment => Colors.indigo,
      CostCenterDimensionCategory.familyAndDependents => Colors.teal,
      CostCenterDimensionCategory.obligationsAndDebts => Colors.deepOrange,
      CostCenterDimensionCategory.investmentsAndProjects =>
        ColorTokens.warningAmber,
      CostCenterDimensionCategory.savingsAndReserves => Colors.purple,
      CostCenterDimensionCategory.entertainmentAndLifestyle => Colors.pink,
      _ => _typeColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final center = dto.center;

    final filtered = _activeDimId == null
        ? dto.recentVouchers
        : dto.recentVouchers
            .where((v) => v.dimensionIds.contains(_activeDimId))
            .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            leading: const BackButton(color: Colors.white),
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: _typeColor,
            actions: [_actionsMenu(context)],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: HeroBackground(
                trend: dto.monthlyTrend,
                typeColor: _typeColor,
                isProfit: _isProfit,
                center: center,
              ),
            ),
          ),

          // ── Body content ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.md,
              SpacingTokens.md,
              SpacingTokens.md,
              100,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Suspended banner
                  if (!center.isActive)
                    Container(
                      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.md,
                        vertical: SpacingTokens.sm,
                      ),
                      decoration: BoxDecoration(
                        color: ColorTokens.warningAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                        border: Border.all(
                          color:
                              ColorTokens.warningAmber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pause_circle_outline_rounded,
                              color: ColorTokens.warningAmber, size: 18),
                          const SizedBox(width: SpacingTokens.sm),
                          Text(
                            AppStringsAr.costCenterSuspendedBadge,
                            style: TextStyle(
                              color: ColorTokens.warningAmber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // KPI Row
                  _buildKpiRow(context, custom, scheme),
                  const SizedBox(height: SpacingTokens.md),

                  // Trend chart
                  _buildTrendCard(context, custom),
                  const SizedBox(height: SpacingTokens.md),

                  // Analytics row: Donut + Budget Gauge
                  if (dto.dimensionBreakdown.isNotEmpty ||
                      center.hasBudget) ...[
                    _buildAnalyticsRow(context, custom),
                    const SizedBox(height: SpacingTokens.md),
                  ],

                  // Dimensions section
                  if (dto.dimensions.isNotEmpty) ...[
                    _sectionHeader(
                        AppStringsAr.costCenterDimensionsTitle, custom),
                    const SizedBox(height: SpacingTokens.xs),
                    ..._groupedDims.entries.map((entry) => _DimensionGroup(
                          category: entry.key,
                          dims: entry.value,
                          color: _getCategoryColor(entry.key),
                        )),
                    const SizedBox(height: SpacingTokens.md),
                  ],

                  // Activity Feed
                  _buildActivitySection(context, custom, filtered),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openChatView(context),
        backgroundColor: _typeColor,
        foregroundColor: Colors.white,
        icon: Icon(_isProfit
            ? Icons.add_circle_outline_rounded
            : Icons.remove_circle_outline_rounded),
        label: Text(_isProfit
            ? AppStringsAr.costCenterQuickReceiveAction
            : AppStringsAr.costCenterQuickPayAction),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────

  Widget _buildKpiRow(
      BuildContext context, QaydCustomColors custom, ColorScheme scheme) {
    final primaryCurrency = dto.center.currencyCode;
    final growthPct = dto.growthPct;

    return Row(
      children: [
        Expanded(
          child: DashKpiCard(
            icon: Icons.receipt_long_rounded,
            label: AppStringsAr.costCenterVoucherCountLabel,
            value: dto.voucherCount.toDouble(),
            formatValue: (v) => v.round().toString(),
            color: _typeColor,
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: DashKpiCard(
            icon: Icons.show_chart_rounded,
            label: AppStringsAr.costCenterCurrentMonthLabel,
            value: (dto.currentMonthTotal / 100),
            formatValue: (v) => _fmt(v.round(), primaryCurrency),
            color: _isProfit ? ColorTokens.emerald500 : ColorTokens.debitBlue,
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: dto.center.hasBudget
              ? DashKpiCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: AppStringsAr.costCenterBudgetPrefix,
                  value: (dto.center.budgetMinorUnits / 100),
                  formatValue: (v) => _fmt(v.round(), primaryCurrency),
                  color: custom.goldAccent,
                )
              : DashKpiCard(
                  icon: growthPct != null && growthPct >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  label: AppStringsAr.costCenterGrowthLabel,
                  value: growthPct?.abs() ?? 0,
                  formatValue: (v) => growthPct == null
                      ? '—'
                      : '${growthPct >= 0 ? '+' : '−'}${v.toStringAsFixed(1)}%',
                  color: growthPct != null && growthPct >= 0
                      ? ColorTokens.emerald500
                      : ColorTokens.errorSoft,
                ),
        ),
      ],
    );
  }

  Widget _buildTrendCard(BuildContext context, QaydCustomColors custom) {
    final hasData = dto.monthlyTrend.any((p) => p.totalMinor > 0);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStringsAr.costCenterTrendSection, custom),
          const SizedBox(height: SpacingTokens.sm),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.lg),
              child: Center(
                child: Text(AppStringsAr.costCenterNoTrendData,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: TrendLineChart(trend: dto.monthlyTrend, color: _typeColor),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(BuildContext context, QaydCustomColors custom) {
    final hasDonut = dto.dimensionBreakdown.isNotEmpty;
    final hasBudget = dto.center.hasBudget;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDonut)
          Expanded(
            flex: 3,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                      AppStringsAr.costCenterDimensionBreakdownTitle, custom),
                  const SizedBox(height: SpacingTokens.xs),
                  SizedBox(
                    height: 180,
                    child: DonutChart(
                      items: dto.dimensionBreakdown,
                      activeDimId: _activeDimId,
                      onTap: (id) => setState(
                          () => _activeDimId = _activeDimId == id ? null : id),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (hasDonut && hasBudget) const SizedBox(width: SpacingTokens.sm),
        if (hasBudget)
          Expanded(
            flex: 2,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                      AppStringsAr.costCenterBudgetGaugeTitle, custom),
                  const SizedBox(height: SpacingTokens.md),
                  BudgetGauge(
                    utilization: dto.budgetUtilization,
                    primaryCurrency: dto.center.currencyCode,
                    totalMinor:
                        dto.totalsByCurrency[dto.center.currencyCode] ?? 0,
                    budgetMinor: dto.center.budgetMinorUnits,
                    typeColor: _typeColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActivitySection(
    BuildContext context,
    QaydCustomColors custom,
    List filtered,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: _sectionHeader(
                    AppStringsAr.costCenterActivitySection, custom)),
            if (_activeDimId != null)
              TextButton(
                onPressed: () => setState(() => _activeDimId = null),
                child: Text(AppStringsAr.costCenterAllDimensionsFilter),
              ),
          ],
        ),
        // Dimension filter chips
        if (dto.dimensionBreakdown.isNotEmpty) ...[
          const SizedBox(height: SpacingTokens.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dto.dimensionBreakdown.map((item) {
                final isSelected = _activeDimId == item.dimensionId;
                return Padding(
                  padding: const EdgeInsets.only(right: SpacingTokens.xs),
                  child: FilterChip(
                    label: Text('${item.dimensionName} (${item.voucherCount})'),
                    selected: isSelected,
                    onSelected: (_) => setState(() =>
                        _activeDimId = isSelected ? null : item.dimensionId),
                    selectedColor: _typeColor.withValues(alpha: 0.2),
                    checkmarkColor: _typeColor,
                    labelStyle: TextStyle(
                      color: isSelected ? _typeColor : null,
                      fontSize: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: SpacingTokens.sm),

        // Voucher cards
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.lg),
            child: Center(
              child: Text(AppStringsAr.costCenterNoRecentVouchers,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          )
        else
          ...filtered.map((v) => VoucherActivityCard(summary: v)),

        const SizedBox(height: SpacingTokens.sm),

        // View more
        const Divider(),
        const SizedBox(height: SpacingTokens.xs),
        FilledButton.icon(
          onPressed: () => _openChatView(context),
          icon: const Icon(Icons.forum_outlined),
          label: Text(AppStringsAr.costCenterViewMoreVouchers),
          style: FilledButton.styleFrom(
            backgroundColor: _typeColor,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, QaydCustomColors custom) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: custom.goldAccent,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static String _fmt(int major, String currency) {
    if (major >= 1000000)
      return '${(major / 1000000).toStringAsFixed(1)}م $currency';
    if (major >= 1000) return '${(major / 1000).toStringAsFixed(1)}ك $currency';
    return '$major $currency';
  }

  // ── Navigation ────────────────────────────────────────────────────────

  Future<void> _openChatView(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => BlocProvider(
          create: (_) => StatementChatCubit(
            listStatement: InjectionContainer.listAccountStatementChatUseCase,
            listAccounts: InjectionContainer.listAccountsUseCase,
            counterpartyAccountId: dto.center.id,
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
            leading: const Icon(Icons.edit_outlined),
            title: const Text(AppStringsAr.costCenterEditAction),
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
                ? AppStringsAr.costCenterSuspendAction
                : AppStringsAr.costCenterActivateAction),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

// ── Dimension Group (kept from original) ──────────────────────────────────

class _DimensionGroup extends StatelessWidget {
  const _DimensionGroup({
    required this.category,
    required this.dims,
    required this.color,
  });

  final CostCenterDimensionCategory category;
  final List<CostCenterDimension> dims;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(category.icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              category.labelAr,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ]),
          const SizedBox(height: SpacingTokens.xs),
          Wrap(
            spacing: SpacingTokens.xs,
            runSpacing: SpacingTokens.xs,
            children: dims
                .map((d) => Chip(
                      label: Text(d.name),
                      backgroundColor: color.withValues(alpha: 0.1),
                      labelStyle: TextStyle(color: color, fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
