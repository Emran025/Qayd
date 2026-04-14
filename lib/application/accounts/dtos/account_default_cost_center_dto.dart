/// Represents a single default cost-center tag that is associated with an
/// account. Used to pre-populate voucher cost-center selectors when the
/// account is chosen on a new receipt/payment voucher.
class AccountDefaultCostCenterDto {
  const AccountDefaultCostCenterDto({
    required this.id,
    required this.accountId,
    required this.costCenterId,
    this.costCenterName,
    this.dimensionIds = const [],
  });

  /// Primary key of the `account_default_cost_centers` row.
  final String id;

  /// The account this default belongs to.
  final String accountId;

  /// The cost center to attach automatically.
  final String costCenterId;

  /// Display name, resolved at read time (nullable — may be missing for
  /// deleted centers, though the FK cascade would remove the row first).
  final String? costCenterName;

  /// Optional dimension IDs to pre-select alongside the cost center.
  final List<String> dimensionIds;
}
