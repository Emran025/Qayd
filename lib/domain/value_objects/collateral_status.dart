/// Lifecycle status of a collateral record.
///
/// - [active]:     Collateral is held as guarantee; debt is outstanding.
/// - [expired]:    The deadline (تاريخ الاستحقاق) has passed; eligible for liquidation.
/// - [liquidated]: Collateral has been sold/settled; accounting entries generated.
/// - [released]:   Debt was paid normally; collateral returned to debtor.
enum CollateralStatus {
  active,
  expired,
  liquidated,
  released;

  bool get isActive => this == CollateralStatus.active;
  bool get isExpired => this == CollateralStatus.expired;
  bool get isLiquidated => this == CollateralStatus.liquidated;
  bool get isReleased => this == CollateralStatus.released;

  /// Whether this collateral can undergo the liquidation workflow.
  bool get canLiquidate => this == CollateralStatus.expired;

  /// Whether terminal (no further transitions allowed).
  bool get isTerminal =>
      this == CollateralStatus.liquidated || this == CollateralStatus.released;

  static CollateralStatus fromString(String val) {
    return CollateralStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => CollateralStatus.active,
    );
  }
}
