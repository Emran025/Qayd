import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';

class CreateAccountInput {
  const CreateAccountInput({
    required this.name,
    this.parentAccountId,
    this.rootStandardKind,
    this.customClassificationName,
    this.customClassificationNature,
    this.isDefault = false,
  });

  final String name;
  final String? parentAccountId;

  /// Required for root accounts when not using a custom classification.
  final StandardAccountClassificationKind? rootStandardKind;

  final String? customClassificationName;
  final AccountNature? customClassificationNature;
  final bool isDefault;
}
