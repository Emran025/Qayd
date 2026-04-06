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
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/pages/accounts/account_statement_chat_page.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_cubit.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_extensions.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_create_page.dart';

// ── Cubit ────────────────────────────────────────────────────────────────────

sealed class _CostCenterDetailState {}

final class _DetailLoading extends _CostCenterDetailState {}

final class _DetailReady extends _CostCenterDetailState {
  _DetailReady(this.dto);
  final CostCenterDetailsDto dto;
}

final class _DetailFailure extends _CostCenterDetailState {
  _DetailFailure(this.failure);
  final Failure failure;
}

final class _CostCenterDetailCubit extends Cubit<_CostCenterDetailState> {
  _CostCenterDetailCubit(this._useCase, this.centerId) : super(_DetailLoading());

  final GetCostCenterDetailsUseCase _useCase;
  final String centerId;

  Future<void> load() async {
    emit(_DetailLoading());
    final result = await _useCase(centerId);
    result.fold(
      (f) => emit(_DetailFailure(f)),
      (dto) => emit(_DetailReady(dto)),
    );
  }

  Future<void> toggleStatus() async {
    final s = state;
    if (s is! _DetailReady) return;

    final center = s.dto.center;
    final res = center.isActive
        ? await InjectionContainer.suspendCostCenterUseCase(center.id)
        : await InjectionContainer.activateCostCenterUseCase(center.id);

    res.fold((_) {}, (_) => load());
  }
}

// ── Page ─────────────────────────────────────────────────────────────────────

class CostCenterDetailPage extends StatelessWidget {
  const CostCenterDetailPage({super.key, required this.centerId});

  final String centerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _CostCenterDetailCubit(
        InjectionContainer.getCostCenterDetailsUseCase,
        centerId,
      )..load(),
      child: const _CostCenterDetailScaffold(),
    );
  }
}

class _CostCenterDetailScaffold extends StatelessWidget {
  const _CostCenterDetailScaffold();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<_CostCenterDetailCubit, _CostCenterDetailState>(
      builder: (context, state) {
        return switch (state) {
          _DetailLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          _DetailFailure(:final failure) => Scaffold(
            appBar: AppBar(title: Text(AppStringsAr.errorTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QaydText(
                      failure.messageAr,
                      slot: QaydTextStyleSlot.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    FilledButton(
                      onPressed: () =>
                          context.read<_CostCenterDetailCubit>().load(),
                      child: Text(AppStringsAr.retryAction),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _DetailReady(:final dto) => _DetailBody(dto: dto),
        };
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.dto});

  final CostCenterDetailsDto dto;

  @override
  Widget build(BuildContext context) {
    final center = dto.center;
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final isProfit = center.type == CostCenterType.profit;
    final typeColor =
        isProfit ? ColorTokens.emerald600 : ColorTokens.debitBlue;

    // Group dimensions by category
    final spatialDims = dto.dimensions
        .where(
          (d) => d.category == CostCenterDimensionCategory.spatial,
        )
        .toList();
    final individualDims = dto.dimensions
        .where(
          (d) => d.category == CostCenterDimensionCategory.individual,
        )
        .toList();
    final projectDims = dto.dimensions
        .where((d) => d.category == CostCenterDimensionCategory.project)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar + hero header ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            leading: const BackButton(),
            actions: [
              _buildActionsMenu(context),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      typeColor.withValues(alpha: 0.85),
                      typeColor.withValues(alpha: 0.45),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SpacingTokens.md,
                      SpacingTokens.xxl,
                      SpacingTokens.md,
                      SpacingTokens.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isProfit
                                  ? Icons.trending_up_rounded
                                  : Icons.pie_chart_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: SpacingTokens.sm),
                            Expanded(
                              child: Text(
                                center.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 2,
                              ),
                            ),
                            if (!center.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: SpacingTokens.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    RadiusTokens.xs,
                                  ),
                                ),
                                child: const Text(
                                  AppStringsAr.costCenterSuspendedBadge,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (center.description != null) ...[
                          const SizedBox(height: SpacingTokens.xs),
                          Text(
                            center.description!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── KPI Cards ───────────────────────────────────────────
                  Row(
                    children: [
                      _KpiCard(
                        label: AppStringsAr.costCenterVoucherCountLabel,
                        value: '${dto.voucherCount}',
                        icon: Icons.receipt_long_rounded,
                        color: typeColor,
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      if (center.hasBudget)
                        _KpiCard(
                          label: AppStringsAr.costCenterBudgetPrefix,
                          value:
                              '${center.budgetMinorUnits ~/ 100} ${center.currencyCode}',
                          icon: Icons.account_balance_wallet_outlined,
                          color: custom.goldAccent,
                        )
                      else
                        _KpiCard(
                          label: AppStringsAr.costCenterTotalLabel,
                          value: dto.totalsByCurrency.isEmpty
                              ? '—'
                              : dto.totalsByCurrency.entries
                                    .map(
                                      (e) =>
                                          '${e.value ~/ 100} ${e.key}',
                                    )
                                    .join(' | '),
                          icon: Icons.show_chart_rounded,
                          color: ColorTokens.emerald500,
                        ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),

                  // ── Dimensions Section ───────────────────────────────────
                  if (dto.dimensions.isNotEmpty) ...[
                    Text(
                      AppStringsAr.costCenterDimensionsTitle,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(
                        color: custom.goldAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),

                    if (spatialDims.isNotEmpty)
                      _DimensionGroup(
                        category: CostCenterDimensionCategory.spatial,
                        dims: spatialDims,
                        color: ColorTokens.debitBlue,
                      ),
                    if (individualDims.isNotEmpty)
                      _DimensionGroup(
                        category: CostCenterDimensionCategory.individual,
                        dims: individualDims,
                        color: ColorTokens.emerald600,
                      ),
                    if (projectDims.isNotEmpty)
                      _DimensionGroup(
                        category: CostCenterDimensionCategory.project,
                        dims: projectDims,
                        color: ColorTokens.warningAmber,
                      ),
                    const SizedBox(height: SpacingTokens.md),
                  ],

                  // ── Open Chat button ─────────────────────────────────────
                  const Divider(),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    AppStringsAr.costCenterLedgerTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(
                      color: custom.goldAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    AppStringsAr.costCenterLedgerSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  FilledButton.icon(
                    onPressed: () => _openChatView(context),
                    icon: const Icon(Icons.forum_outlined),
                    label: Text(AppStringsAr.costCenterOpenLedger),
                    style: FilledButton.styleFrom(
                      backgroundColor: typeColor,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'status') {
          context.read<_CostCenterDetailCubit>().toggleStatus();
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
            leading: Icon(
              dto.center.isActive
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
            ),
            title: Text(
              dto.center.isActive
                  ? AppStringsAr.costCenterSuspendAction
                  : AppStringsAr.costCenterActivateAction,
            ),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
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
      context.read<_CostCenterDetailCubit>().load();
    }
  }

  Future<void> _openChatView(BuildContext context) async {
    // The cost center itself is the "counterparty" in the chat view
    // We reuse AccountStatementChatPage with the cost center's account as the filter.
    // Note: The cost center ID is used as the "counterparty" identifier — 
    // the StatementChatCubit will filter vouchers by the cost center.
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => BlocProvider(
          create: (_) => StatementChatCubit(
            listStatement: InjectionContainer.listAccountStatementChatUseCase,
            listAccounts: InjectionContainer.listAccountsUseCase,
            counterpartyAccountId: dto.center.id,
          )..load(),
          child: AccountStatementChatPage(
            counterpartyAccountId: dto.center.id,
          ),
        ),
      ),
    );
  }
}

// ── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dimension Group ───────────────────────────────────────────────────────────

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
          Row(
            children: [
              Icon(
                category.icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                category.labelAr,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Wrap(
            spacing: SpacingTokens.xs,
            runSpacing: SpacingTokens.xs,
            children: dims
                .map(
                  (d) => Chip(
                    label: Text(d.name),
                    backgroundColor: color.withValues(alpha: 0.1),
                    labelStyle: TextStyle(color: color, fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
