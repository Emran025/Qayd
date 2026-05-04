import 'package:flutter/material.dart';
import 'package:qayd/application/cost_centers/dtos/cost_center_details_dto.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_dashboard_widgets.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// The analytical visualization section for the cost center detail page.
///
/// Uses a clean layout where:
/// - The trend chart sits in a full-width surface with no heavy card borders
/// - Donut chart and budget gauge sit side by side in a single row
/// - Section labels are subtle, uppercase-style for a fintech feel
class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({
    super.key,
    required this.dto,
    required this.typeColor,
    required this.isProfit,
    required this.activeDimId,
    required this.onDimTap,
  });

  final CostCenterDetailsDto dto;
  final Color typeColor;
  final bool isProfit;
  final String? activeDimId;
  final ValueChanged<String> onDimTap;

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasDonut = dto.dimensionBreakdown.isNotEmpty;
    final hasBudget = dto.center.hasBudget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Trend Chart ──────────────────────────────────────────
        _buildTrendCard(context, scheme, tt, custom),
        SizedBox(height: SpacingTokens.md + 4),

        // ── Analytics row: Donut + Budget Gauge ──────────────────
        if (hasDonut || hasBudget) ...[
          _buildAnalyticsRow(context, scheme, tt, custom, hasDonut, hasBudget),
        ],
      ],
    );
  }

  Widget _buildTrendCard(
    BuildContext context,
    ColorScheme scheme,
    TextTheme tt,
    QaydCustomColors custom,
  ) {
    final primaryCurrency = dto.center.currencyCode;
    final hasData = dto.monthlyTrend.any(
      (p) => (p.totalsByCurrency[primaryCurrency] ?? 0) > 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      padding:  EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubtleLabel(text: AppStrings.costCenterTrendSection),
          SizedBox(height: SpacingTokens.sm + 4),
          if (!hasData)
            SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  AppStrings.costCenterNoTrendData,
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: TrendLineChart(
                trend: dto.monthlyTrend,
                color: typeColor,
                primaryCurrency: primaryCurrency,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(
    BuildContext context,
    ColorScheme scheme,
    TextTheme tt,
    QaydCustomColors custom,
    bool hasDonut,
    bool hasBudget,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDonut)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SubtleLabel(
                    text: AppStrings.costCenterDimensionBreakdownTitle,
                  ),
                  SizedBox(height: SpacingTokens.xs),
                  SizedBox(
                    height: 180,
                    child: DonutChart(
                      items: dto.dimensionBreakdown,
                      activeDimId: activeDimId,
                      onTap: onDimTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (hasDonut && hasBudget) SizedBox(width: SpacingTokens.sm),
        if (hasBudget)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SubtleLabel(
                    text: AppStrings.costCenterBudgetGaugeTitle,
                  ),
                  SizedBox(height: SpacingTokens.md),
                  BudgetGauge(
                    utilization: dto.budgetUtilization,
                    primaryCurrency: dto.center.currencyCode,
                    totalMinor:
                        dto.totalsByCurrency[dto.center.currencyCode] ?? 0,
                    budgetMinor: dto.center.budgetMinorUnits,
                    typeColor: typeColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A minimal section label — small caps feel with muted colour.
class _SubtleLabel extends StatelessWidget {
  const _SubtleLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
    );
  }
}
