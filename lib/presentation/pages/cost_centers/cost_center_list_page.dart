import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_create_page.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_detail_page.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_list_cubit.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_list_state.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_extensions.dart';

class CostCenterListPage extends StatelessWidget {
  const CostCenterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CostCenterListCubit(
        listUseCase: InjectionContainer.listCostCentersUseCase,
        suspendUseCase: InjectionContainer.suspendCostCenterUseCase,
        activateUseCase: InjectionContainer.activateCostCenterUseCase,
      )..load(),
      child: const _CostCenterListScaffold(),
    );
  }
}

class _CostCenterListScaffold extends StatefulWidget {
  const _CostCenterListScaffold();

  @override
  State<_CostCenterListScaffold> createState() =>
      _CostCenterListScaffoldState();
}

class _CostCenterListScaffoldState extends State<_CostCenterListScaffold> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      QaydPageRoute.slideFromStart<bool>(
        builder: (_) => CostCenterCreatePage(onCreated: () {}),
      ),
    );
    if (created == true && mounted) {
      await context.read<CostCenterListCubit>().load();
    }
  }

  Future<void> _openDetail(CostCenter center) async {
    await Navigator.of(context).push<void>(
      QaydPageRoute.slideFromStart<void>(
        builder: (_) => CostCenterDetailPage(centerId: center.id),
      ),
    );
    if (mounted) {
      await context.read<CostCenterListCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final custom = Theme.of(context).extension<QaydCustomColors>()!;

    return Scaffold(
      appBar: QaydAppBar(title: AppStringsAr.costCentersTitle),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_cost_center_list',
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppStringsAr.addCostCenterFab),
        backgroundColor: gold,
        foregroundColor: ColorTokens.navy950,
      ),
      body: Column(
        children: [
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.md,
              SpacingTokens.sm,
              SpacingTokens.md,
              SpacingTokens.xs,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStringsAr.searchCostCentersHint,
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                ),
                isDense: true,
              ),
              onChanged: (q) =>
                  context.read<CostCenterListCubit>().setSearchQuery(q),
            ),
          ),

          // ── Filter chips ──
          BlocBuilder<CostCenterListCubit, CostCenterListState>(
            builder: (context, state) {
              final ready = state is CostCenterListReady;
              final typeFilter = ready ? state.typeFilter : null;
              final showSuspended = ready ? state.showSuspended : false;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.xs,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Type filters
                      ChoiceChip(
                        label: Text(AppStringsAr.allLabel),
                        selected: typeFilter == null,
                        onSelected: (_) => context
                            .read<CostCenterListCubit>()
                            .setTypeFilter(null),
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      ChoiceChip(
                        label: Text(AppStringsAr.costCenterTypeCostGroup),
                        selected: typeFilter == CostCenterType.cost,
                        onSelected: (_) => context
                            .read<CostCenterListCubit>()
                            .setTypeFilter(CostCenterType.cost),
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      ChoiceChip(
                        label: Text(AppStringsAr.costCenterTypeProfitGroup),
                        selected: typeFilter == CostCenterType.profit,
                        onSelected: (_) => context
                            .read<CostCenterListCubit>()
                            .setTypeFilter(CostCenterType.profit),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.sm,
                        ),
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.5),
                      ),
                      // Suspended toggle
                      FilterChip(
                        label: Text(AppStringsAr.showSuspendedLabel),
                        selected: showSuspended,
                        onSelected: (v) => context
                            .read<CostCenterListCubit>()
                            .setShowSuspended(v),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── List ──
          Expanded(
            child: BlocBuilder<CostCenterListCubit, CostCenterListState>(
              builder: (context, state) {
                return switch (state) {
                  CostCenterListInitial() || CostCenterListLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  CostCenterListFailure(:final failure) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(SpacingTokens.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: custom.subtleBorder,
                          ),
                          const SizedBox(height: SpacingTokens.md),
                          QaydText(
                            failure.messageAr,
                            slot: QaydTextStyleSlot.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: SpacingTokens.md),
                          FilledButton.tonal(
                            onPressed: () =>
                                context.read<CostCenterListCubit>().load(),
                            child: Text(AppStringsAr.retryAction),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CostCenterListReady(:final filteredCenters) =>
                    filteredCenters.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 64,
                                  color: custom.subtleBorder,
                                ),
                                const SizedBox(height: SpacingTokens.md),
                                QaydText(
                                  AppStringsAr.costCentersEmpty,
                                  slot: QaydTextStyleSlot.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                context.read<CostCenterListCubit>().load(),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                left: SpacingTokens.md,
                                right: SpacingTokens.md,
                                bottom: SpacingTokens.xxl,
                              ),
                              itemCount: filteredCenters.length,
                              itemBuilder: (ctx, i) => _CostCenterCard(
                                center: filteredCenters[i],
                                onTap: () => _openDetail(filteredCenters[i]),
                                onSuspend: () => context
                                    .read<CostCenterListCubit>()
                                    .suspend(filteredCenters[i].id),
                                onActivate: () => context
                                    .read<CostCenterListCubit>()
                                    .activate(filteredCenters[i].id),
                              ),
                            ),
                          ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _CostCenterCard extends StatelessWidget {
  const _CostCenterCard({
    required this.center,
    required this.onTap,
    required this.onSuspend,
    required this.onActivate,
  });

  final CostCenter center;
  final VoidCallback onTap;
  final VoidCallback onSuspend;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final scheme = Theme.of(context).colorScheme;

    final isProfit = center.type == CostCenterType.profit;
    final typeColor = isProfit ? ColorTokens.emerald600 : ColorTokens.debitBlue;
    final typeIcon = center.type.icon;

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Type Icon Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 22),
                    ),
                    const SizedBox(width: SpacingTokens.sm),

                    // Name + type label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            center.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: SpacingTokens.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    RadiusTokens.xs,
                                  ),
                                ),
                                child: Text(
                                  center.type.labelAr,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: typeColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              if (!center.isActive) ...[
                                const SizedBox(width: SpacingTokens.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: SpacingTokens.sm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorTokens.errorSoft.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      RadiusTokens.xs,
                                    ),
                                  ),
                                  child: Text(
                                    AppStringsAr.costCenterSuspendedBadge,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: ColorTokens.errorDeep,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onSelected: (v) {
                        if (v == 'suspend') onSuspend();
                        if (v == 'activate') onActivate();
                      },
                      itemBuilder: (_) => [
                        if (center.isActive)
                          PopupMenuItem(
                            value: 'suspend',
                            child: Row(
                              children: [
                                const Icon(Icons.pause_circle_outline_rounded),
                                const SizedBox(width: 8),
                                Text(AppStringsAr.costCenterSuspendAction),
                              ],
                            ),
                          )
                        else
                          PopupMenuItem(
                            value: 'activate',
                            child: Row(
                              children: [
                                const Icon(Icons.play_circle_outline_rounded),
                                const SizedBox(width: 8),
                                Text(AppStringsAr.costCenterActivateAction),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Description
                if (center.description != null &&
                    center.description!.isNotEmpty) ...[
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    center.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Budget progress if set
                if (center.hasBudget) ...[
                  const SizedBox(height: SpacingTokens.sm),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: SpacingTokens.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 14,
                        color: custom.goldAccent,
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        '${AppStringsAr.costCenterBudgetPrefix} ${center.budgetMinorUnits ~/ 100} ${center.currencyCode}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: custom.goldAccent,
                        ),
                      ),
                    ],
                  ),
                ],

                // Navigate hint
                const SizedBox(height: SpacingTokens.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppStringsAr.costCenterViewVouchers,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: typeColor),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: typeColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
