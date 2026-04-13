import 'package:flutter/material.dart';
import 'package:qayd/application/cost_centers/dtos/cost_center_details_dto.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/numerical_styling.dart';

/// A clean, card-free inline metrics strip instead of heavy KPI boxes.
///
/// Shows three data points separated by thin vertical dividers:
///   Voucher Count · This Month · Growth / Budget
///
/// The metrics sit inside a single surface container with very subtle
/// chrome — letting the numbers do the visual work through typographic
/// contrast alone.
class FinancialMetricsGrid extends StatefulWidget {
  const FinancialMetricsGrid({
    super.key,
    required this.dto,
    required this.typeColor,
    required this.isProfit,
  });

  final CostCenterDetailsDto dto;
  final Color typeColor;
  final bool isProfit;

  @override
  State<FinancialMetricsGrid> createState() => _FinancialMetricsGridState();
}

class _FinancialMetricsGridState extends State<FinancialMetricsGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // final tt = Theme.of(context).textTheme;
    final dto = widget.dto;
    final currency = dto.center.currencyCode;
    final growthPct = dto.growthPct;

    final currentMonthVals = dto.currentMonthTotals.isEmpty
        ? ['0']
        : dto.currentMonthTotals.entries
            .map((e) => _fmt(e.value ~/ 100, e.key))
            .toList();

    final items = <_MetricData>[
      _MetricData(
        label: AppStringsAr.costCenterVoucherCountLabel,
        values: [dto.voucherCount.toString()],
        icon: Icons.receipt_long_rounded,
        accent: widget.typeColor,
      ),
      _MetricData(
        label: AppStringsAr.costCenterCurrentMonthLabel,
        values: currentMonthVals,
        icon: Icons.calendar_today_rounded,
        accent:
            widget.isProfit ? ColorTokens.emerald500 : ColorTokens.debitBlue,
      ),
      if (dto.center.hasBudget)
        _MetricData(
          label: AppStringsAr.costCenterBudgetPrefix,
          values: [_fmt(dto.center.budgetMinorUnits ~/ 100, currency)],
          icon: Icons.account_balance_wallet_outlined,
          accent: ColorTokens.warningAmber,
        )
      else
        _MetricData(
          label: AppStringsAr.costCenterGrowthLabel,
          values: [
            growthPct == null
                ? '—'
                : '${growthPct >= 0 ? '+' : ''}${growthPct.toStringAsFixed(1)}%'
          ],
          icon: growthPct != null && growthPct >= 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          accent: growthPct != null && growthPct >= 0
              ? ColorTokens.emerald500
              : ColorTokens.errorSoft,
        ),
    ];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(RadiusTokens.lg),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: SpacingTokens.md,
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      indent: 6,
                      endIndent: 6,
                      color: scheme.onSurface.withValues(alpha: 0.06),
                    ),
                  Expanded(
                    child: _buildMetric(
                      context,
                      items[i],
                      _stagger(i, items.length),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  double _stagger(int index, int total) {
    final start = index / (total + 0.5);
    final end = (index + 1.2) / (total + 0.5);
    return Interval(
      start.clamp(0, 1),
      end.clamp(0, 1),
      curve: Curves.easeOutCubic,
    ).transform(_ctrl.value);
  }

  Widget _buildMetric(BuildContext context, _MetricData data, double t) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Opacity(
      opacity: t.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - t)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 18, color: data.accent),
            const SizedBox(height: SpacingTokens.xs + 2),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: data.values.map((v) {
                return Text.rich(
                  buildNumericalScaledSpan(
                    v,
                    TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: data.values.length > 1 ? 14 : 16,
                      height: 1.1,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                );
              }).toList(),
            ),
            const SizedBox(height: 2),
            Text(
              data.label,
              style: tt.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int major, String currency) {
    if (major == 0) return '0';
    if (major >= 1000000) {
      return '${(major / 1000000).toStringAsFixed(1)}م $currency';
    }
    if (major >= 1000) {
      return '${(major / 1000).toStringAsFixed(1)}ك $currency';
    }
    return '$major $currency';
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.values,
    required this.icon,
    required this.accent,
  });
  final String label;
  final List<String> values;
  final IconData icon;
  final Color accent;
}
