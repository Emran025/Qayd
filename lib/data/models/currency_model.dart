/// SQLite projection for [currencies] table.
final class CurrencyModel {
  const CurrencyModel({
    required this.code,
    required this.nameAr,
    required this.symbol,
    required this.fractionalDigits,
    required this.isPredefined,
    required this.isActive,
    required this.createdAtIso,
  });

  final String code;
  final String nameAr;
  final String symbol;
  final int fractionalDigits;
  final bool isPredefined;
  final bool isActive;
  final String createdAtIso;

  Map<String, Object?> toMap() => {
        'code': code,
        'name_ar': nameAr,
        'symbol': symbol,
        'fractional_digits': fractionalDigits,
        'is_predefined': isPredefined ? 1 : 0,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAtIso,
      };

  factory CurrencyModel.fromMap(Map<String, Object?> map) {
    return CurrencyModel(
      code: map['code']! as String,
      nameAr: map['name_ar']! as String,
      symbol: map['symbol']! as String,
      fractionalDigits: map['fractional_digits']! as int,
      isPredefined: (map['is_predefined']! as int) == 1,
      isActive: (map['is_active']! as int) == 1,
      createdAtIso: map['created_at']! as String,
    );
  }
}
