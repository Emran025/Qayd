import 'package:qayd/presentation/l10n/app_strings.dart';

abstract final class ClassificationUtil {
  static String getLocalizedGroupName(String key) {
    return switch (key.toLowerCase()) {
      'assets' => AppStrings.assetsLabel,
      'liabilities' => AppStrings.liabilitiesLabel,
      'equity' => AppStrings.equityLabel,
      'revenue' => AppStrings.personalRevenue,
      'expense' => AppStrings.personalExpenses,
      'receivables' => AppStrings.accountsReceivableYours,
      'payables' => AppStrings.accountsPayableYouOwe,
      _ => key,
    };
  }
}
