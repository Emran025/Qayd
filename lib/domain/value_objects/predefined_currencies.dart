import 'package:qayd/domain/value_objects/currency_code.dart';

/// Predefined regional currencies seeded on first run.
///
/// All predefined currencies behave identically to user-defined currencies.
abstract final class PredefinedCurrencies {
  static const sar = CurrencyCode(
    code: 'SAR',
    nameAr: 'ريال سعودي',
    symbol: '﷼',
    fractionalDigits: 2,
  );
  static const yer = CurrencyCode(
    code: 'YER',
    nameAr: 'ريال يمني',
    symbol: '﷼',
    fractionalDigits: 2,
  );
  static const usd = CurrencyCode(
    code: 'USD',
    nameAr: 'دولار أمريكي',
    symbol: '\$',
    fractionalDigits: 2,
  );
  static const eur = CurrencyCode(
    code: 'EUR',
    nameAr: 'يورو',
    symbol: '€',
    fractionalDigits: 2,
    isActive: false,
  );
  static const aed = CurrencyCode(
    code: 'AED',
    nameAr: 'درهم إماراتي',
    symbol: 'د.إ',
    fractionalDigits: 2,
    isActive: false,
  );
  static const kwd = CurrencyCode(
    code: 'KWD',
    nameAr: 'دينار كويتي',
    symbol: 'د.ك',
    fractionalDigits: 3,
    isActive: false,
  );
  static const bhd = CurrencyCode(
    code: 'BHD',
    nameAr: 'دينار بحريني',
    symbol: 'د.ب',
    fractionalDigits: 3,
    isActive: false,
  );
  static const omr = CurrencyCode(
    code: 'OMR',
    nameAr: 'ريال عماني',
    symbol: '﷼',
    fractionalDigits: 3,
    isActive: false,
  );
  static const qar = CurrencyCode(
    code: 'QAR',
    nameAr: 'ريال قطري',
    symbol: '﷼',
    fractionalDigits: 2,
    isActive: false,
  );
  static const egp = CurrencyCode(
    code: 'EGP',
    nameAr: 'جنيه مصري',
    symbol: 'ج.م',
    fractionalDigits: 2,
    isActive: false,
  );
  static const jod = CurrencyCode(
    code: 'JOD',
    nameAr: 'دينار أردني',
    symbol: 'د.ا',
    fractionalDigits: 3,
    isActive: false,
  );

  static const List<CurrencyCode> all = [
    sar, yer, usd, eur, aed, kwd, bhd, omr, qar, egp, jod,
  ];
}
