/// Strongly-typed identifier for collateral records.
final class CollateralId {
  const CollateralId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CollateralId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'CollateralId($value)';
}
