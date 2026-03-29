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

  /// Standard: الأصول
  static const AccountClassification assets = AccountClassification._(
    standardKind: StandardAccountClassificationKind.assets,
    defaultNature: AccountNature.debit,
  );

  /// Standard: الالتزامات
  static const AccountClassification liabilities = AccountClassification._(
    standardKind: StandardAccountClassificationKind.liabilities,
    defaultNature: AccountNature.credit,
  );

  /// Standard: حقوق الملكية
  static const AccountClassification equity = AccountClassification._(
    standardKind: StandardAccountClassificationKind.equity,
    defaultNature: AccountNature.credit,
  );

  /// Standard: الإيرادات
  static const AccountClassification income = AccountClassification._(
    standardKind: StandardAccountClassificationKind.income,
    defaultNature: AccountNature.credit,
  );

  /// Standard: المصروفات
  static const AccountClassification expenses = AccountClassification._(
    standardKind: StandardAccountClassificationKind.expenses,
    defaultNature: AccountNature.debit,
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
