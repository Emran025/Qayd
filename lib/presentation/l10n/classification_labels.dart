import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


String standardClassificationKindLabelAr(
  StandardAccountClassificationKind kind,
) {
  switch (kind) {
    case StandardAccountClassificationKind.liquidAssets:
      return AppStrings.cashAndLiquidity;
    case StandardAccountClassificationKind.receivables:
      return AppStrings.rightsAndEntitlements;
    case StandardAccountClassificationKind.payables:
      return AppStrings.obligationsAndDebts;
    case StandardAccountClassificationKind.settlements:
      return AppStrings.financialAndPersonalSettlements;
    case StandardAccountClassificationKind.personalExpenses:
      return AppStrings.expensesAndConsumption;
    case StandardAccountClassificationKind.personalRevenues:
      return AppStrings.revenuesAndGains;
    case StandardAccountClassificationKind.clearingRemittances:
      return AppStrings.remittanceClearing;
    case StandardAccountClassificationKind.remittanceFees:
      return AppStrings.transferFees;
    case StandardAccountClassificationKind.fixedDepreciableAssets:
      return AppStrings.fixedAssetsDepreciated;
    case StandardAccountClassificationKind.fixedProfitableAssets:
      return AppStrings.fixedAssetsProfitable;
  }
}
