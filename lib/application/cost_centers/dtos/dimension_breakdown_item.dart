/// Per-dimension voucher count for the donut chart breakdown.
final class DimensionBreakdownItem {
  const DimensionBreakdownItem({
    required this.dimensionId,
    required this.dimensionName,
    required this.categoryId,
    required this.voucherCount,
  });

  final String dimensionId;
  final String dimensionName;

  /// Category ID (e.g. 'spatial', 'individual', 'project').
  final String categoryId;

  final int voucherCount;
}
