/// Utility to map ISO currency codes to Arabic names.
abstract final class CurrencyUtil {
  static String getArabicName(String code) {
    switch (code.toUpperCase()) {
      case 'SAR':
        return '﷼ سعودي';
      case 'YER':
        return '﷼ يمني';
      case 'USD':
        return 'دولار أمريكي';
      case 'AED':
        return 'درهم إماراتي';
      case 'EGP':
        return 'جنيه مصري';
      case 'KWD':
        return 'دينار كويتي';
      case 'BHD':
        return 'دينار بحريني';
      case 'OMR':
        return '﷼ عماني';
      case 'QAR':
        return '﷼ قطري';
      case 'TRY':
        return 'ليرة تركية';
      case 'EUR':
        return 'يورو';
      case 'GBP':
        return 'جنيه إسترليني';
      default:
        return code;
    }
  }

  /// Formats currency for display by using the Arabic name if available.
  static String formatCurrency(String code) {
    return getArabicName(code);
  }
}
