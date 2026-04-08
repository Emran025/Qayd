import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';

String standardClassificationKindLabelAr(
  StandardAccountClassificationKind kind,
) {
  switch (kind) {
    case StandardAccountClassificationKind.liquidAssets:
      return 'نقدية وسيولة';
    case StandardAccountClassificationKind.receivables:
      return 'حقوق ومستحقات';
    case StandardAccountClassificationKind.payables:
      return 'التزامات وديون';
    case StandardAccountClassificationKind.settlements:
      return 'تسويات مالية وشخصية';
    case StandardAccountClassificationKind.personalExpenses:
      return 'مصروفات واستهلاك';
    case StandardAccountClassificationKind.personalRevenues:
      return 'إيرادات ومكاسب';
    case StandardAccountClassificationKind.clearingRemittances:
      return 'مقاصة الحوالات';
    case StandardAccountClassificationKind.remittanceFees:
      return 'رسوم الحوالات';
    case StandardAccountClassificationKind.fixedDepreciableAssets:
      return 'أصول ثابتة (مهلكة)';
    case StandardAccountClassificationKind.fixedProfitableAssets:
      return 'أصول ثابتة (ربحية)';
  }
}
