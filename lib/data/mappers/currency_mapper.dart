import 'package:qayd/data/models/currency_model.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';

final class CurrencyMapper {
  static CurrencyModel toModel(CurrencyCode currency, {bool isPredefined = false}) {
    return CurrencyModel(
      code: currency.code,
      nameAr: currency.nameAr,
      symbol: currency.symbol,
      fractionalDigits: currency.fractionalDigits,
      isPredefined: isPredefined,
      createdAtIso: DateTime.now().toIso8601String(),
    );
  }

  static CurrencyCode toEntity(CurrencyModel model) {
    return CurrencyCode(
      code: model.code,
      nameAr: model.nameAr,
      symbol: model.symbol,
      fractionalDigits: model.fractionalDigits,
    );
  }
}
