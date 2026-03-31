import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';

/// Standard chart-of-accounts bucket or a user-defined classification with explicit nature.
final class AccountClassification {
  const AccountClassification._({
    required this.defaultNature,
    this.standardKind,
    this.customName,
  }) : assert(
          standardKind != null || customName != null,
          'Either standard or custom classification',
        );

  /// Standard: نقدية (Liquid Assets)
  static const AccountClassification liquidAssets = AccountClassification._(
    standardKind: StandardAccountClassificationKind.liquidAssets,
    defaultNature: AccountNature.debit,
  );

  /// Standard: ذمم مدينة (Receivables)
  static const AccountClassification receivables = AccountClassification._(
    standardKind: StandardAccountClassificationKind.receivables,
    defaultNature: AccountNature.debit,
  );

  /// Standard: ذمم دائنة (Payables)
  static const AccountClassification payables = AccountClassification._(
    standardKind: StandardAccountClassificationKind.payables,
    defaultNature: AccountNature.credit,
  );

  /// Standard: تسوية وشخصي (Settlements)
  static const AccountClassification settlements = AccountClassification._(
    standardKind: StandardAccountClassificationKind.settlements,
    defaultNature: AccountNature.credit,
  );

  final StandardAccountClassificationKind? standardKind;
  final String? customName;

  /// Nature used for balance direction for every account under this classification.
  final AccountNature defaultNature;

  factory AccountClassification.custom({
    required String name,
    required AccountNature nature,
  }) {
    final n = name.trim();
    if (n.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Custom classification name required');
    }
    return AccountClassification._(
      standardKind: null,
      customName: n,
      defaultNature: nature,
    );
  }

  bool get isStandard => standardKind != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountClassification &&
        standardKind == other.standardKind &&
        customName == other.customName &&
        defaultNature == other.defaultNature;
  }

  @override
  int get hashCode => Object.hash(standardKind, customName, defaultNature);
}
