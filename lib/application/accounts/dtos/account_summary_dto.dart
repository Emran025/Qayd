/// Lightweight account row for lists (no domain entity exposure).
class AccountSummaryDto {
  const AccountSummaryDto({
    required this.id,
    required this.name,
    required this.natureCode,
    required this.isActive,
    required this.isRoot,
    this.parentId,
    this.standardClassificationKind,
    this.customClassificationName,
    required this.balancesMinorUnits,
    this.metadata,
  });

  final String id;
  final String name;
  final String natureCode;
  final bool isActive;
  final bool isRoot;
  final String? parentId;

  /// `StandardAccountClassificationKind.name` when standard; null if custom root bucket.
  final String? standardClassificationKind;

  /// Set when classification is custom; section title for grouping.
  final String? customClassificationName;

  /// Map of currency code to signed balance in minor units.
  final Map<String, int> balancesMinorUnits;

  /// Additional extensible data for the account.
  final Map<String, dynamic>? metadata;
}
