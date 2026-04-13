import 'package:qayd/application/cost_centers/dtos/center_voucher_summary.dart';
import 'package:qayd/application/cost_centers/dtos/dimension_breakdown_item.dart';
import 'package:qayd/application/cost_centers/dtos/monthly_trend_point.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';

/// Full DTO for the cost center dashboard — entity + all analytical metrics.
final class CostCenterDetailsDto {
  const CostCenterDetailsDto({
    required this.center,
    required this.dimensions,
    required this.totalsByCurrency,
    required this.voucherCount,
    this.recentVouchers = const [],
    this.monthlyTrend = const [],
    this.dimensionBreakdown = const [],
  });

  final CostCenter center;
  final List<CostCenterDimension> dimensions;

  /// Total confirmed amounts by currency code (minor units).
  final Map<String, int> totalsByCurrency;

  final int voucherCount;

  /// Last 10 vouchers for the integrated activity feed.
  final List<CenterVoucherSummary> recentVouchers;

  /// Last 6 months of confirmed totals for the trend chart.
  final List<MonthlyTrendPoint> monthlyTrend;

  /// Per-dimension voucher counts for the donut chart.
  final List<DimensionBreakdownItem> dimensionBreakdown;

  // ── Computed KPIs ────────────────────────────────────────────────────────

  /// Budget utilisation 0.0..1.0+ (may exceed 1.0 if over-budget).
  double get budgetUtilization {
    if (!center.hasBudget) return 0.0;
    final total = totalsByCurrency[center.currencyCode] ?? 0;
    return total / center.budgetMinorUnits;
  }

  /// Current month total in minor units grouped by currency.
  Map<String, int> get currentMonthTotals =>
      monthlyTrend.isEmpty ? const {} : monthlyTrend.last.totalsByCurrency;

  /// Previous month total in minor units grouped by currency.
  Map<String, int> get prevMonthTotals => monthlyTrend.length < 2
      ? const {}
      : monthlyTrend[monthlyTrend.length - 2].totalsByCurrency;

  /// Month-over-month growth percentage for the primary currency (null if no previous data).
  double? get growthPct {
    final pc = center.currencyCode;
    final curr = currentMonthTotals[pc] ?? 0;
    final prev = prevMonthTotals[pc] ?? 0;
    if (prev == 0) return null;
    return (curr - prev) / prev * 100;
  }

  /// Average voucher size in minor units across all currencies combined.
  double get avgVoucherSizeMinor {
    if (voucherCount == 0) return 0;
    final total = totalsByCurrency.values.fold<int>(0, (a, b) => a + b);
    return total / voucherCount;
  }
}
