/// Output DTO from a collateral liquidation operation.
class LiquidationResult {
  const LiquidationResult({
    required this.settlementVoucherId,
    required this.settledAmountMinor,
    required this.surplusAmountMinor,
    this.surplusReceiptVoucherId,
  });

  /// The settlement voucher ID generated for debt clearance.
  final String settlementVoucherId;

  /// If the sale value exceeds the debt, this is the auto-generated
  /// receipt voucher ID for the surplus "Held for Customer".
  final String? surplusReceiptVoucherId;

  /// The amount of debt actually settled (in minor currency units).
  final int settledAmountMinor;

  /// The surplus amount (sale value - debt), 0 if no surplus.
  final int surplusAmountMinor;

  /// Whether a surplus receipt was automatically created.
  bool get hasSurplus => surplusAmountMinor > 0;
}
