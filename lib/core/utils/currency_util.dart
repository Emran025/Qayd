import 'package:qayd/presentation/l10n/app_strings_ar.dart';
/// Utility to map ISO currency codes to Arabic names.
abstract final class CurrencyUtil {
  static String getArabicName(String code) {
    switch (code.toUpperCase()) {
      case 'SAR':
        return AppStringsAr.saudiRiyals;
      case 'YER':
        return AppStringsAr.yemeni;
      case 'USD':
        return AppStringsAr.usDollars;
      case 'AED':
        return AppStringsAr.emiratiDirham;
      case 'EGP':
        return AppStringsAr.egyptianPound;
      case 'KWD':
        return AppStringsAr.kuwaitiDinar;
      case 'BHD':
        return AppStringsAr.bahrainiDinar;
      case 'OMR':
        return AppStringsAr.omani;
      case 'QAR':
        return AppStringsAr.qatari;
      case 'TRY':
        return AppStringsAr.turkishLira;
      case 'EUR':
        return AppStringsAr.euro;
      case 'GBP':
        return AppStringsAr.britishPounds;
      case 'XAU':
        return AppStringsAr.aGramOfGold;
      case 'XAG':
        return AppStringsAr.aGramOfSilver;
      default:
        return code;
    }
  }

  /// Formats currency for display by using the Arabic name if available.
  static String formatCurrency(String code) {
    return getArabicName(code);
  }
}
