import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


/// Predefined regional currencies seeded on first run.
///
/// All predefined currencies behave identically to user-defined currencies.
abstract final class PredefinedCurrencies {
  static const sar = CurrencyCode(
    code: 'SAR',
    nameAr: AppStringsAr.saudiRiyals,
    symbol: '﷼',
    fractionalDigits: 2,
  );
  static const yer = CurrencyCode(
    code: 'YER',
    nameAr: AppStringsAr.yemeni,
    symbol: '﷼',
    fractionalDigits: 2,
  );
  static const usd = CurrencyCode(
    code: 'USD',
    nameAr: AppStringsAr.usDollars,
    symbol: '\$',
    fractionalDigits: 2,
  );
  static const eur = CurrencyCode(
    code: 'EUR',
    nameAr: AppStringsAr.euro,
    symbol: '€',
    fractionalDigits: 2,
    isActive: false,
  );
  static const aed = CurrencyCode(
    code: 'AED',
    nameAr: AppStringsAr.emiratiDirham,
    symbol: AppStringsAr.de,
    fractionalDigits: 2,
    isActive: false,
  );
  static const kwd = CurrencyCode(
    code: 'KWD',
    nameAr: AppStringsAr.kuwaitiDinar,
    symbol: AppStringsAr.kwd,
    fractionalDigits: 3,
    isActive: false,
  );
  static const bhd = CurrencyCode(
    code: 'BHD',
    nameAr: AppStringsAr.bahrainiDinar,
    symbol: AppStringsAr.bear,
    fractionalDigits: 3,
    isActive: false,
  );
  static const omr = CurrencyCode(
    code: 'OMR',
    nameAr: AppStringsAr.omani,
    symbol: '﷼',
    fractionalDigits: 3,
    isActive: false,
  );
  static const qar = CurrencyCode(
    code: 'QAR',
    nameAr: AppStringsAr.qatari,
    symbol: '﷼',
    fractionalDigits: 2,
    isActive: false,
  );
  static const egp = CurrencyCode(
    code: 'EGP',
    nameAr: AppStringsAr.egyptianPound,
    symbol: AppStringsAr.jm,
    fractionalDigits: 2,
    isActive: false,
  );
  static const jod = CurrencyCode(
    code: 'JOD',
    nameAr: AppStringsAr.jordanianDinar,
    symbol: AppStringsAr.da,
    fractionalDigits: 3,
    isActive: false,
  );
  static const xau = CurrencyCode(
    code: 'XAU',
    nameAr: AppStringsAr.aGramOfGold,
    symbol: AppStringsAr.cD,
    fractionalDigits: 2,
    isActive: false,
  );
  static const xag = CurrencyCode(
    code: 'XAG',
    nameAr: AppStringsAr.gramOfSilver,
    symbol: AppStringsAr.dry,
    fractionalDigits: 2,
    isActive: false,
  );

  static const List<CurrencyCode> all = [
    sar,
    yer,
    usd,
    eur,
    aed,
    kwd,
    bhd,
    omr,
    qar,
    egp,
    jod,
    xau,
    xag,
  ];
}
