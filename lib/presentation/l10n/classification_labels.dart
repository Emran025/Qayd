import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


String standardClassificationKindLabelAr(
  StandardAccountClassificationKind kind,
) {
  switch (kind) {
    case StandardAccountClassificationKind.liquidAssets:
      return AppStringsAr.cashAndLiquidity;
    case StandardAccountClassificationKind.receivables:
      return AppStringsAr.rightsAndEntitlements;
    case StandardAccountClassificationKind.payables:
      return AppStringsAr.obligationsAndDebts;
    case StandardAccountClassificationKind.settlements:
      return AppStringsAr.financialAndPersonalSettlements;
    case StandardAccountClassificationKind.personalExpenses:
      return AppStringsAr.expensesAndConsumption;
    case StandardAccountClassificationKind.personalRevenues:
      return AppStringsAr.revenuesAndGains;
    case StandardAccountClassificationKind.clearingRemittances:
      return AppStringsAr.remittanceClearing;
    case StandardAccountClassificationKind.remittanceFees:
      return AppStringsAr.transferFees;
    case StandardAccountClassificationKind.fixedDepreciableAssets:
      return AppStringsAr.fixedAssetsDepreciated;
    case StandardAccountClassificationKind.fixedProfitableAssets:
      return AppStringsAr.fixedAssetsProfitable;
  }
}
