/// ISO 4217 or user-defined currency classification label.
///
/// Real, virtual, and custom currencies are structurally identical.
/// There is no hierarchy or special status among currency types.
class CurrencyCode {
  const CurrencyCode({
    required this.code,
    required this.nameAr,
    required this.symbol,
    this.fractionalDigits = 2,
    this.isActive = true,
  });

  /// ISO 4217 code or user-defined identifier (e.g., 'SAR', 'BTC', 'PTS').
  final String code;

  /// Arabic display name (e.g., AppStringsAr.saudiRiyals).
  final String nameAr;

  /// Currency symbol (e.g., '﷼', '$', '€').
  final String symbol;

  /// Decimal places for this currency (e.g., 2 for SAR, 3 for KWD, 0 for JPY).
  final int fractionalDigits;

  /// Whether the currency should be displayed in selection menus for new transactions.
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CurrencyCode && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'CurrencyCode($code)';
}
