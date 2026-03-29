import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';

String standardClassificationKindLabelAr(
  StandardAccountClassificationKind kind,
) {
  switch (kind) {
    case StandardAccountClassificationKind.assets:
      return 'أصول';
    case StandardAccountClassificationKind.liabilities:
      return 'التزامات';
    case StandardAccountClassificationKind.equity:
      return 'حقوق ملكية';
    case StandardAccountClassificationKind.income:
      return 'إيرادات';
    case StandardAccountClassificationKind.expenses:
      return 'مصروفات';
  }
}
