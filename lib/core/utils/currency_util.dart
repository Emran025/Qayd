import 'package:qayd/presentation/l10n/app_strings.dart';
/// Utility to map ISO currency codes to localized names.
abstract final class CurrencyUtil {
  static String getLocalizedName(String code) {
    switch (code.toUpperCase()) {
      case 'SAR':
        return AppStrings.saudiRiyals;
      case 'YER':
        return AppStrings.yemeni;
      case 'USD':
        return AppStrings.usDollars;
      case 'AED':
        return AppStrings.emiratiDirham;
      case 'EGP':
        return AppStrings.egyptianPound;
      case 'KWD':
        return AppStrings.kuwaitiDinar;
      case 'BHD':
        return AppStrings.bahrainiDinar;
      case 'OMR':
        return AppStrings.omani;
      case 'QAR':
        return AppStrings.qatari;
      case 'TRY':
        return AppStrings.turkishLira;
      case 'EUR':
        return AppStrings.euro;
      case 'GBP':
        return AppStrings.britishPounds;
      case 'XAU':
        return AppStrings.aGramOfGold;
      case 'XAG':
        return AppStrings.aGramOfSilver;
      default:
        return code;
    }
  }

  /// Formats currency for display by using the localized name if available.
  static String formatCurrency(String code) {
    return getLocalizedName(code);
  }

  static String getSymbol(String code) {
    switch (code.toUpperCase()) {
      case 'SAR':
        return '﷼';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'YER':
        return '﷼.ي';
      case 'AED':
        return AppStrings.de;
      case 'KWD':
        return AppStrings.kwd;
      case 'BHD':
        return AppStrings.bear;
      case 'OMR':
        return '﷼';
      case 'QAR':
        return '﷼';
      case 'EGP':
        return AppStrings.jm;
      case 'JOD':
        return AppStrings.da;
      case 'XAU':
        return AppStrings.cD;
      case 'XAG':
        return AppStrings.dry;
      default:
        return code;
    }
  }
}
