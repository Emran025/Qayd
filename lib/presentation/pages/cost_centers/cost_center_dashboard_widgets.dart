import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:qayd/application/cost_centers/dtos/center_voucher_summary.dart';
import 'package:qayd/application/cost_centers/dtos/dimension_breakdown_item.dart';
import 'package:qayd/application/cost_centers/dtos/monthly_trend_point.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:intl/intl.dart';
import 'package:qayd/presentation/utils/numerical_styling.dart';

// ── Glass Card ────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(RadiusTokens.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(RadiusTokens.lg),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: child,
        ),
      ),
    );
  }
}

// ── Hero Background ───────────────────────────────────────────────────────

class HeroBackground extends StatelessWidget {
  const HeroBackground({
    super.key,
    required this.trend,
    required this.typeColor,
    required this.isProfit,
    required this.center,
  });

  final List<MonthlyTrendPoint> trend;
  final Color typeColor;
  final bool isProfit;
  final CostCenter center;

  @override
  Widget build(BuildContext context) {
    final hasData = trend.any((p) => p.totalMinor > 0);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            typeColor.withValues(alpha: 0.9),
            typeColor.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasData)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.3,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: trend.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(),
                                e.value.totalMinor.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Colors.white,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
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
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  if (center.description != null) ...[
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      center.description!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dash KPI Card ─────────────────────────────────────────────────────────

class DashKpiCard extends StatefulWidget {
  const DashKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    required this.formatValue,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color? color;
  final String Function(double) formatValue;

  @override
  State<DashKpiCard> createState() => _DashKpiCardState();
}

class _DashKpiCardState extends State<DashKpiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant DashKpiCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _anim = Tween<double>(begin: _anim.value, end: widget.value)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = widget.color ?? scheme.primary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(widget.icon, color: c, size: 24),
          const SizedBox(height: SpacingTokens.sm),
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => Text.rich(
              buildNumericalScaledSpan(
                widget.formatValue(_anim.value),
                TextStyle(
                  color: c,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Trend Line Chart ──────────────────────────────────────────────────────

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({super.key, required this.trend, required this.color});
  final List<MonthlyTrendPoint> trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Find max value for Y axis padding
    var maxY = trend.map((e) => e.totalMinor.toDouble()).reduce(max);
    if (maxY == 0) maxY = 100; // prevent empty chart issues

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (value) => FlLine(
            color: scheme.onSurface.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= trend.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    trend[index].shortLabel,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (trend.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.2,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.surfaceContainerHighest,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  (spot.y / 100).toStringAsFixed(0),
                  TextStyle(color: color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: trend.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.totalMinor.toDouble());
            }).toList(),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: scheme.surface,
                strokeWidth: 2,
                strokeColor: color,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }
}

// ── Donut Chart ───────────────────────────────────────────────────────────

class DonutChart extends StatefulWidget {
  const DonutChart(
      {super.key, required this.items, this.activeDimId, required this.onTap});
  final List<DimensionBreakdownItem> items;
  final String? activeDimId;
  final ValueChanged<String> onTap;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox();

    // Generate nice colors for donut
    final colors = [
      ColorTokens.debitBlue,
      ColorTokens.emerald500,
      ColorTokens.warningAmber,
      ColorTokens.navy700,
      ColorTokens.slate400,
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF43F5E), // Rose
      const Color(0xFF06B6D4), // Cyan
    ];

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                    if (event is FlTapUpEvent &&
                        _touchedIndex >= 0 &&
                        _touchedIndex < widget.items.length) {
                      widget.onTap(widget.items[_touchedIndex].dimensionId);
                    }
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: widget.items.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                final isTouched = i == _touchedIndex;
                final isSelected = widget.activeDimId == item.dimensionId;
                final isOtherSelected =
                    widget.activeDimId != null && !isSelected;

                final radius = isTouched || isSelected ? 40.0 : 30.0;
                final opacity = isOtherSelected ? 0.3 : 1.0;
                final c = colors[i % colors.length].withValues(alpha: opacity);

                return PieChartSectionData(
                  color: c,
                  value: item.voucherCount.toDouble(),
                  title: item.voucherCount.toString(),
                  radius: radius,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
            swapAnimationDuration: const Duration(milliseconds: 500),
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          flex: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.items.take(4).toList().asMap().entries.map((e) {
              final item = e.value;
              final c = colors[e.key % colors.length];
              final isSelected = widget.activeDimId == item.dimensionId;
              final isOtherSelected = widget.activeDimId != null && !isSelected;

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: () => widget.onTap(item.dimensionId),
                  child: AnimatedOpacity(
                    opacity: isOtherSelected ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: c, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.dimensionName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Budget Gauge ──────────────────────────────────────────────────────────

class BudgetGauge extends StatefulWidget {
  const BudgetGauge({
    super.key,
    required this.utilization,
    required this.primaryCurrency,
    required this.totalMinor,
    required this.budgetMinor,
    required this.typeColor,
  });

  final double utilization;
  final String primaryCurrency;
  final int totalMinor;
  final int budgetMinor;
  final Color typeColor;

  @override
  State<BudgetGauge> createState() => _BudgetGaugeState();
}

class _BudgetGaugeState extends State<BudgetGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _anim = Tween<double>(begin: 0, end: widget.utilization)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant BudgetGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.utilization != widget.utilization) {
      _anim = Tween<double>(begin: _anim.value, end: widget.utilization)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOver = widget.utilization > 1.0;

    // Gauge colors
    final activeColor = isOver ? ColorTokens.errorSoft : widget.typeColor;
    final bgColor = scheme.onSurface.withValues(alpha: 0.1);

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final val = _anim.value;
                final displayVal = min(val, 1.0); // max 100% for the arc
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: 180,
                        sectionsSpace: 0,
                        centerSpaceRadius: 35,
                        sections: [
                          PieChartSectionData(
                            color: activeColor,
                            value: displayVal * 100,
                            radius: 12,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: bgColor,
                            value: (1 - displayVal) * 100,
                            radius: 12,
                            showTitle: false,
                          ),
                          // Hidden section to make it a semi-circle
                          PieChartSectionData(
                            color: Colors.transparent,
                            value: 100,
                            radius: 12,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 25,
                      child: Text.rich(
                        buildNumericalScaledSpan(
                          '${(val * 100).toStringAsFixed(0)}%',
                          TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: activeColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
        ),
        if (isOver)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 14, color: ColorTokens.errorSoft),
              const SizedBox(width: 4),
              Text(
                AppStringsAr.costCenterOverBudgetWarning,
                style: const TextStyle(
                    color: ColorTokens.errorSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ],
          )
        else
          Text.rich(
            buildNumericalScaledSpan(
              '${widget.totalMinor ~/ 100} / ${widget.budgetMinor ~/ 100} ${widget.primaryCurrency}',
              TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Voucher Activity Card ─────────────────────────────────────────────────

class VoucherActivityCard extends StatelessWidget {
  const VoucherActivityCard({super.key, required this.summary});
  final CenterVoucherSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isReceipt = summary.type == VoucherType.receipt;
    final c = isReceipt ? ColorTokens.debitBlue : ColorTokens.creditGreen;
    final icon =
        isReceipt ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: c.withValues(alpha: 0.1),
          foregroundColor: c,
          child: Icon(icon, size: 20),
        ),
        title: Text(
          summary.counterpartyName ?? AppStringsAr.voucherStateConfirmed,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary.description?.isNotEmpty == true)
              Text(
                summary.description!,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Text(
              DateFormat('yyyy-MM-dd').format(summary.date),
              style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
            ),
          ],
        ),
        trailing: Text.rich(
          buildNumericalScaledSpan(
            '${summary.amountMinor ~/ 100} ${summary.currencyCode}',
            TextStyle(
              fontWeight: FontWeight.w900,
              color: c,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
