import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized configuration for report headers (UI & PDF).
///
/// Encapsulates the branding logic, fetching user-defined titles/subtitles
/// from [SharedPreferences] with appropriate fallbacks to [AppStrings].
class QaydHeaderConfig {
  final String title;
  final String subtitle;
  final String englishTitle;
  final String englishSubtitle;

  const QaydHeaderConfig({
    required this.title,
    required this.subtitle,
    required this.englishTitle,
    required this.englishSubtitle,
  });

  /// Factory to resolve configuration from persistent settings.
  factory QaydHeaderConfig.resolve(
    SharedPreferences prefs, {
    String? titleOverride,
    String? subtitleOverride,
    bool isStatement = false,
  }) {
    // Determine fallbacks based on report type
    final defaultArTitle = isStatement
        ? AppStrings.accountStatement
        : AppStrings.entryPersonalAccounting;
    final defaultArSubtitle = isStatement
        ? AppStrings.accountStatementASystem
        : AppStrings.cryptocurrencySystem;

    // Prefs keys are shared for "PDF Header" which represents the general branding
    final prefsTitle = prefs.getString('pdf_header_title');
    final prefsSubtitle = prefs.getString('pdf_header_subtitle');

    return QaydHeaderConfig(
      title: titleOverride ?? prefsTitle ?? defaultArTitle,
      subtitle: subtitleOverride ?? prefsSubtitle ?? defaultArSubtitle,
      englishTitle: 'Qayd — Personal Accounting',
      englishSubtitle: 'Encrypted Financial Voucher System',
    );
  }
}
