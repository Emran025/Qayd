import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';

String standardClassificationKindLabelAr(
  StandardAccountClassificationKind kind,
) {
  switch (kind) {
    case StandardAccountClassificationKind.liquidAssets:
      return 'نقدية';
    case StandardAccountClassificationKind.receivables:
      return 'ذمم مدينة - لي';
    case StandardAccountClassificationKind.payables:
      return 'ذمم دائنة - علي';
    case StandardAccountClassificationKind.settlements:
      return 'تسوية وشخصي';
    case StandardAccountClassificationKind.personalExpenses:
      return 'مصروفات شخصية';
    case StandardAccountClassificationKind.personalRevenues:
      return 'إيرادات شخصية';
  }
}
