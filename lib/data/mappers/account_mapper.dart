import 'package:qayd/data/models/account_model.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';

final class AccountMapper {
  static AccountModel toModel(Account account) {
    final std = account.classification.standardKind;
    return AccountModel(
      id: account.id.value,
      name: account.name,
      nature: account.nature.name,
      parentId: account.parentId?.value,
      isDefault: account.isDefault,
      isActive: account.isActive,
      createdAtIso: account.createdAt.toIso8601String(),
      standardClassification: std?.name,
      customClassificationName: account.classification.customName,
      customClassificationNature:
          std == null ? account.classification.defaultNature.name : null,
    );
  }

  static Account toEntity(AccountModel model) {
    final classification = _classificationFromModel(model);
    final nature = _parseNature(model.nature);
    return Account.restore(
      id: AccountId(model.id),
      name: model.name,
      nature: nature,
      classification: classification,
      parentId: model.parentId != null ? AccountId(model.parentId!) : null,
      isDefault: model.isDefault,
      createdAt: DateTime.parse(model.createdAtIso),
      isActive: model.isActive,
    );
  }

  static AccountClassification _classificationFromModel(AccountModel model) {
    final std = model.standardClassification;
    if (std != null) {
      return switch (StandardAccountClassificationKind.values.byName(std)) {
        StandardAccountClassificationKind.liquidAssets =>
          AccountClassification.liquidAssets,
        StandardAccountClassificationKind.receivables =>
          AccountClassification.receivables,
        StandardAccountClassificationKind.payables =>
          AccountClassification.payables,
        StandardAccountClassificationKind.settlements =>
          AccountClassification.settlements,
        StandardAccountClassificationKind.personalExpenses =>
          AccountClassification.personalExpenses,
        StandardAccountClassificationKind.personalRevenues =>
          AccountClassification.personalRevenues,
      };
    }
    return AccountClassification.custom(
      name: model.customClassificationName!,
      nature: _parseNature(model.customClassificationNature!),
    );
  }

  static AccountNature _parseNature(String raw) {
    return AccountNature.values.byName(raw);
  }
}
