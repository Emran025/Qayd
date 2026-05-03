import 'package:qayd/application/cost_centers/dtos/center_voucher_summary.dart';
import 'package:qayd/application/cost_centers/dtos/cost_center_details_dto.dart';
import 'package:qayd/application/cost_centers/dtos/dimension_breakdown_item.dart';
import 'package:qayd/application/cost_centers/dtos/monthly_trend_point.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


final class GetCostCenterDetailsUseCase {
  const GetCostCenterDetailsUseCase(this._repository);

  final CostCenterRepository _repository;

  Future<Result<CostCenterDetailsDto>> call(String id) async {
    final centerResult = await _repository.getById(id);
    return centerResult.fold(
      (f) => FailureResult(f),
      (center) async {
        if (center == null) {
          return const FailureResult(
            ValidationFailure(
              messageAr: AppStringsAr.costCenterDoesNot,
              code: 'cost_center_not_found',
            ),
          );
        }

        // Fetch all data concurrently for maximum performance
        final dimsResult = await _repository.getAllDimensions(
          costCenterId: id,
          activeOnly: true,
        );
        final totalsResult = await _repository.getTotalsByCenter(id);
        final voucherIdsResult =
            await _repository.getVoucherIdsForCostCenter(id);
        final trendResult =
            await _repository.getMonthlyTrendForCenter(id, months: 6);
        final recentResult =
            await _repository.getRecentVouchersForCenter(id, limit: 10);
        final breakdownResult = await _repository.getDimensionBreakdown(id);

        final dims = dimsResult.fold((_) => <dynamic>[], (d) => d);
        final totals = totalsResult.fold((_) => <String, int>{}, (t) => t);
        final voucherIds = voucherIdsResult.fold((_) => <String>[], (v) => v);
        final rawTrend = trendResult.fold(
          (_) => <Map<String, dynamic>>[],
          (t) => t,
        );
        final rawVouchers = recentResult.fold(
          (_) => <Map<String, dynamic>>[],
          (v) => v,
        );
        final rawBreakdown = breakdownResult.fold(
          (_) => <Map<String, dynamic>>[],
          (b) => b,
        );

        final monthlyTrend = _normalizeMonthlyTrend(rawTrend);
        final recentVouchers = rawVouchers.map(_mapVoucher).toList();
        final dimensionBreakdown = rawBreakdown.map(_mapBreakdown).toList();

        return Success(
          CostCenterDetailsDto(
            center: center,
            dimensions: List.from(dims),
            totalsByCurrency: totals,
            voucherCount: (voucherIds as List).length,
            recentVouchers: recentVouchers,
            monthlyTrend: monthlyTrend,
            dimensionBreakdown: dimensionBreakdown,
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Fills zero-value slots for months with no confirmed activity so the
  /// trend chart always spans exactly [months] columns.
  static List<MonthlyTrendPoint> _normalizeMonthlyTrend(
    List<Map<String, dynamic>> raw, {
    int months = 6,
  }) {
    final now = DateTime.now();
    final rawMap = <String, Map<String, int>>{};

    for (final r in raw) {
      final key = r['month_key'] as String;
      final currency = r['currency_code'] as String;
      final minor = (r['total_minor'] as num).toInt();
      rawMap.putIfAbsent(key, () => {})[currency] = minor;
    }

    final result = <MonthlyTrendPoint>[];
    for (var i = months - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      result.add(
        MonthlyTrendPoint(
          monthKey: key,
          totalsByCurrency: rawMap[key] ?? const {},
        ),
      );
    }
    return result;
  }

  static CenterVoucherSummary _mapVoucher(Map<String, dynamic> r) {
    return CenterVoucherSummary(
      id: r['id'] as String,
      type: (r['type'] as String) == 'receipt'
          ? VoucherType.receipt
          : VoucherType.payment,
      amountMinor: (r['amount_minor'] as num).toInt(),
      currencyCode: r['currency_code'] as String,
      description: r['description'] as String?,
      date: DateTime.parse(r['date'] as String),
      counterpartyName: r['counterparty_name'] as String?,
      dimensionIds: List<String>.from(
        (r['dimension_ids'] as List?) ?? const [],
      ),
    );
  }

  static DimensionBreakdownItem _mapBreakdown(Map<String, dynamic> r) {
    return DimensionBreakdownItem(
      dimensionId: r['dimension_id'] as String,
      dimensionName: r['dimension_name'] as String,
      categoryId: r['category_id'] as String,
      voucherCount: (r['voucher_count'] as num).toInt(),
    );
  }
}
