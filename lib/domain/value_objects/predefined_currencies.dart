import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// Predefined regional currencies seeded on first run.
///
/// All predefined currencies behave identically to user-defined currencies.
abstract final class PredefinedCurrencies {
  static CurrencyCode get sar => CurrencyCode(
        code: 'SAR',
        nameAr: AppStrings.saudiRiyals,
        symbol: '﷼',
        fractionalDigits: 2,
      );
  static CurrencyCode get yer => CurrencyCode(
        code: 'YER',
        nameAr: AppStrings.yemeni,
        symbol: '﷼',
        fractionalDigits: 2,
      );
  static CurrencyCode get usd => CurrencyCode(
        code: 'USD',
        nameAr: AppStrings.usDollars,
        symbol: '\$',
        fractionalDigits: 2,
      );
  static CurrencyCode get eur => CurrencyCode(
        code: 'EUR',
        nameAr: AppStrings.euro,
        symbol: '€',
        fractionalDigits: 2,
        isActive: false,
      );
  static CurrencyCode get aed => CurrencyCode(
        code: 'AED',
        nameAr: AppStrings.emiratiDirham,
        symbol: AppStrings.de,
        fractionalDigits: 2,
        isActive: false,
      );
  static CurrencyCode get kwd => CurrencyCode(
        code: 'KWD',
        nameAr: AppStrings.kuwaitiDinar,
        symbol: AppStrings.kwd,
        fractionalDigits: 3,
        isActive: false,
      );
  static CurrencyCode get bhd => CurrencyCode(
        code: 'BHD',
        nameAr: AppStrings.bahrainiDinar,
        symbol: AppStrings.bear,
        fractionalDigits: 3,
        isActive: false,
      );
  static CurrencyCode get omr => CurrencyCode(
        code: 'OMR',
        nameAr: AppStrings.omani,
        symbol: '﷼',
        fractionalDigits: 3,
        isActive: false,
      );
  static CurrencyCode get qar => CurrencyCode(
        code: 'QAR',
        nameAr: AppStrings.qatari,
        symbol: '﷼',
        fractionalDigits: 2,
        isActive: false,
      );
  static CurrencyCode get egp => CurrencyCode(
        code: 'EGP',
        nameAr: AppStrings.egyptianPound,
        symbol: AppStrings.jm,
        fractionalDigits: 2,
        isActive: false,
      );
  static CurrencyCode get jod => CurrencyCode(
        code: 'JOD',
        nameAr: AppStrings.jordanianDinar,
        symbol: AppStrings.da,
        fractionalDigits: 3,
        isActive: false,
      );
  static CurrencyCode get xau => CurrencyCode(
        code: 'XAU',
        nameAr: AppStrings.aGramOfGold,
        symbol: AppStrings.cD,
        fractionalDigits: 2,
        isActive: false,
      );
  static CurrencyCode get xag => CurrencyCode(
        code: 'XAG',
        nameAr: AppStrings.gramOfSilver,
        symbol: AppStrings.dry,
        fractionalDigits: 2,
        isActive: false,
      );

  static List<CurrencyCode> get all => [
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
