import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/application/accounts/dtos/create_account_output.dart';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';

class CreateAccountUseCase {
  CreateAccountUseCase(
    this._accountRepository,
    this._idGenerator,
    this._writeGuard,
  );

  final AccountRepository _accountRepository;
  final IdGenerator _idGenerator;
  final GovernanceWriteGuard _writeGuard;

  Future<Result<CreateAccountOutput>> call(CreateAccountInput input) async {
    try {
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }
      final id = AccountId(_idGenerator.next());
      final now = DateTime.now();
      if (input.parentAccountId == null) {
        _validateRootClassification(input);
        final classification = _rootClassification(input);
        final account = Account.createRoot(
          id: id,
          name: input.name,
          classification: classification,
          createdAt: now,
          isDefault: input.isDefault,
        );
        final saved = await _accountRepository.save(account);
        return saved.fold(
          (f) => FailureResult(f),
          (_) => Success(
            CreateAccountOutput(
              accountId: account.id.value,
              name: account.name,
              natureCode: _natureCode(account),
              isRoot: account.isRoot,
              parentAccountId: account.parentId?.value,
              createdAtIso: account.createdAt.toIso8601String(),
            ),
          ),
        );
      }

      final parentR = await _accountRepository.getById(
        AccountId(input.parentAccountId!),
      );
      if (parentR.isFailure) {
        return FailureResult(parentR.failureOrNull!);
      }
      final parent = parentR.valueOrNull!;
      final child = Account.createChild(
        id: id,
        name: input.name,
        parent: parent,
        createdAt: now,
        isDefault: input.isDefault,
      );
      final saved = await _accountRepository.save(child);
      return saved.fold(
        (f) => FailureResult(f),
        (_) => Success(
          CreateAccountOutput(
            accountId: child.id.value,
            name: child.name,
            natureCode: _natureCode(child),
            isRoot: child.isRoot,
            parentAccountId: child.parentId?.value,
            createdAtIso: child.createdAt.toIso8601String(),
          ),
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }

  void _validateRootClassification(CreateAccountInput input) {
    final hasStd = input.rootStandardKind != null;
    final hasCustom = input.customClassificationName != null &&
        input.customClassificationNature != null;
    if (hasStd == hasCustom) {
      throw ArgumentError(
        'يجب اختيار تصنيف قياسي أو تصنيف مخصص للحساب الجذر.',
      );
    }
    if (hasCustom &&
        input.customClassificationName!.trim().isEmpty) {
      throw ArgumentError('اسم التصنيف المخصص مطلوب.');
    }
  }

  AccountClassification _rootClassification(CreateAccountInput input) {
    final k = input.rootStandardKind;
    if (k != null) {
      switch (k) {
        case StandardAccountClassificationKind.assets:
          return AccountClassification.assets;
        case StandardAccountClassificationKind.liabilities:
          return AccountClassification.liabilities;
        case StandardAccountClassificationKind.equity:
          return AccountClassification.equity;
        case StandardAccountClassificationKind.income:
          return AccountClassification.income;
        case StandardAccountClassificationKind.expenses:
          return AccountClassification.expenses;
      }
    }
    return AccountClassification.custom(
      name: input.customClassificationName!,
      nature: input.customClassificationNature!,
    );
  }

  String _natureCode(Account account) =>
      account.nature == AccountNature.debit ? 'debit' : 'credit';
}
