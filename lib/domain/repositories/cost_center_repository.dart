import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';

abstract interface class CostCenterRepository {
  // ── Cost Centers ──────────────────────────────────────────────────────────

  Future<Result<List<CostCenter>>> getAll({bool activeOnly = false});

  Future<Result<CostCenter?>> getById(String id);

  Future<Result<void>> save(CostCenter center);

  Future<Result<void>> delete(String id);

  // ── Dimensions ────────────────────────────────────────────────────────────

  Future<Result<List<CostCenterDimension>>> getAllDimensions({
    String? costCenterId,
    bool activeOnly = false,
  });

  Future<Result<void>> saveDimension(CostCenterDimension dimension);

  Future<Result<void>> deleteDimension(String id);

  // ── Categories (Classifications) ──────────────────────────────────────────

  Future<Result<List<CostCenterDimensionCategory>>> getAllCategories();

  Future<Result<void>> saveCategory(CostCenterDimensionCategory category);

  // ── Voucher Associations ──────────────────────────────────────────────────

  /// Attach a voucher to a cost center with optional dimension tags.
  Future<Result<void>> attachVoucher({
    required String voucherId,
    required String costCenterId,
    List<String> dimensionIds = const [],
  });

  /// Remove a voucher association from a cost center.
  Future<Result<void>> detachVoucher({
    required String voucherId,
    required String costCenterId,
  });

  /// All cost center IDs associated with a given voucher.
  Future<Result<List<String>>> getCostCenterIdsForVoucher(String voucherId);

  /// Voucher IDs attached to a cost center (for the chat view).
  Future<Result<List<String>>> getVoucherIdsForCostCenter(
    String costCenterId, {
    String? dimensionId,
    DateTime? fromDate,
    DateTime? toDate,
  });

  // ── KPIs ──────────────────────────────────────────────────────────────────

  /// Total amount (in minor units) of confirmed vouchers attached to a center.
  Future<Result<Map<String, int>>> getTotalsByCenter(String costCenterId);

  // ── Analytics ─────────────────────────────────────────────────────────────

  /// Last [months] calendar months of confirmed totals for this center.
  /// Each map contains 'month_key' (String 'YYYY-MM') and 'total_minor' (int).
  Future<Result<List<Map<String, dynamic>>>> getMonthlyTrendForCenter(
    String costCenterId, {
    int months = 6,
  });

  /// Last [limit] voucher summaries attached to this center.
  /// Each map contains: id, type, amount_minor, currency_code, description?,
  /// date, counterparty_name?, dimension_ids (List<String>).
  Future<Result<List<Map<String, dynamic>>>> getRecentVouchersForCenter(
    String costCenterId, {
    int limit = 10,
  });

  /// Per-dimension voucher counts for the donut chart.
  /// Each map contains: dimension_id, dimension_name, category_id, voucher_count.
  Future<Result<List<Map<String, dynamic>>>> getDimensionBreakdown(
    String costCenterId,
  );
}
