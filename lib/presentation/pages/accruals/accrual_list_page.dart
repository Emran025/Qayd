import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/accrual_component.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/accruals/accrual_create_page.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_dashboard_widgets.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class AccrualListPage extends StatefulWidget {
  const AccrualListPage({super.key});

  @override
  State<AccrualListPage> createState() => _AccrualListPageState();
}

class _AccrualListPageState extends State<AccrualListPage> {
  bool _loading = true;
  List<AccrualComponent> _accruals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await InjectionContainer.listAccrualsUseCase();
    if (!mounted) return;
    res.fold(
      (_) => setState(() => _loading = false),
      (data) => setState(() {
        _accruals = data;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;
    final totalMonthly = _calculateMonthlyTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.accrualListTitle),
        leading: const BackButton(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => AccrualCreatePage(onCreated: _load)),
        ),
        label: Text(AppStrings.accrualAddFab),
        icon: Icon(Icons.add_task_rounded),
        backgroundColor: gold,
        foregroundColor: ColorTokens.navy950,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Hero Summary ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _HeroSummary(
                    totalMonthly: totalMonthly,
                    activeCount:
                        _accruals.where((e) => e.isActive).length,
                    dueSoonCount: _countDueSoon(),
                  ),
                ),

                // ── List ───────────────────────────────────────────────────
                if (_accruals.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: QaydText(
                        AppStrings.accrualEmptyState,
                        slot: QaydTextStyleSlot.bodyMedium,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _AccrualCard(
                          item: _accruals[index],
                          onProcessed: _load,
                        ),
                        childCount: _accruals.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  double _calculateMonthlyTotal() {
    double total = 0;
    for (final a in _accruals) {
      if (!a.isActive) continue;
      switch (a.frequency) {
        case AccrualFrequency.daily:
          total += a.amount * 30;
        case AccrualFrequency.weekly:
          total += a.amount * 4;
        case AccrualFrequency.monthly:
          total += a.amount;
        case AccrualFrequency.quarterly:
          total += a.amount / 3;
        case AccrualFrequency.semiAnnually:
          total += a.amount / 6;
        case AccrualFrequency.yearly:
          total += a.amount / 12;
        case AccrualFrequency.once:
          total += 0;
      }
    }
    return total;
  }

  int _countDueSoon() {
    final soon = DateTime.now().add(const Duration(days: 7));
    return _accruals
        .where((e) => e.isActive && e.nextDueDate.isBefore(soon))
        .length;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Summary Section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.totalMonthly,
    required this.activeCount,
    required this.dueSoonCount,
  });

  final double totalMonthly;
  final int activeCount;
  final int dueSoonCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.md,
      ),
      decoration:  BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorTokens.navy900, ColorTokens.navy800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          QaydText(
            AppStrings.accrualMonthlySummaryLabel,
            slot: QaydTextStyleSlot.labelSmall,
            color: Colors.white70,
          ),
          SizedBox(height: SpacingTokens.xs),
          Text(
            '${NumberFormat.decimalPattern('en').format(totalMonthly)} SAR',
            style: textTheme.displayMedium?.copyWith(
              color: ColorTokens.goldAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: SpacingTokens.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _KpiChip(
                label: AppStrings.accrualActiveLabel,
                value: activeCount.toString(),
                icon: Icons.check_circle_outline_rounded,
                color: ColorTokens.emerald400,
              ),
              _KpiChip(
                label: AppStrings.accrualDueSoonLabel,
                value: dueSoonCount.toString(),
                icon: Icons.access_time_rounded,
                color: ColorTokens.warningAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI Chip (replaces _SummaryItem with theme-aligned typography)
// ─────────────────────────────────────────────────────────────────────────────

class _KpiChip extends StatelessWidget {
  const _KpiChip({
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
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accrual Card
// ─────────────────────────────────────────────────────────────────────────────

class _AccrualCard extends StatelessWidget {
   _AccrualCard({required this.item, required this.onProcessed});
  final AccrualComponent item;
  final VoidCallback onProcessed;

  Future<void> _onPay(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);

    final confirm = await QaydDialog.show<bool>(
      context: context,
      icon: Icons.payments_rounded,
      title: AppStrings.accrualProcessConfirmTitle,
      content: AppStrings.accrualProcessConfirmBody(
        item.amount,
        item.currencyCode,
      ),
      secondaryActionLabel: AppStrings.actionCancel,
      onSecondaryAction: () => Navigator.pop(context, false),
      primaryActionLabel: AppStrings.accrualProcessConfirmAction,
      onPrimaryAction: () => Navigator.pop(context, true),
    );

    if (confirm != true) return;

    final res = await InjectionContainer.processAccrualUseCase(item.id);
    res.fold(
      (f) => scaffold.showSnackBar(SnackBar(content: Text(f.messageAr))),
      (_) {
        scaffold.showSnackBar(
          SnackBar(content: Text(AppStrings.accrualProcessedSuccess)),
        );
        onProcessed();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDueSoon =
        item.nextDueDate.isBefore(DateTime.now().add(const Duration(days: 3)));

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: GlassCard(
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ── Indicator strip ──────────────────────────────────────────
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color:
                      isDueSoon ? ColorTokens.errorSoft : ColorTokens.debitBlue,
                  borderRadius: BorderRadius.circular(RadiusTokens.pill),
                ),
              ),
              SizedBox(width: SpacingTokens.sm),

              // ── Content ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.amount} ${item.currencyCode}',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      item.frequency.labelAr,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(height: SpacingTokens.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.event_repeat_rounded,
                          size: 12,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${AppStrings.accrualNextDuePrefix}: ${DateFormat('yyyy-MM-dd', 'en').format(item.nextDueDate)}',
                          style: textTheme.labelSmall?.copyWith(
                            color: isDueSoon
                                ? ColorTokens.errorSoft
                                : scheme.onSurfaceVariant,
                            fontWeight:
                                isDueSoon ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: SpacingTokens.sm),

              // ── Action ───────────────────────────────────────────────────
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => _onPay(context),
                    icon: Icon(Icons.payments_rounded, size: 20),
                    tooltip: AppStrings.accrualPayTooltip,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          ColorTokens.emerald400.withValues(alpha: 0.1),
                      foregroundColor: ColorTokens.emerald400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
