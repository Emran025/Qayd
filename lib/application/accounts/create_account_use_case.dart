import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/application/accounts/dtos/create_account_output.dart';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';
import 'package:qayd/domain/entities/party_details.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/core/error/failures.dart';

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

      // Check for uniqueness of phone number and email for Counterparties.
      if (input.phoneNumber?.isNotEmpty == true) {
        final existingByPhone =
            await _accountRepository.findAccountByPhone(input.phoneNumber!);
        if (existingByPhone.valueOrNull != null) {
          return const FailureResult(ValidationFailure(
            messageAr: 'يوجد حساب مسجل مسبقاً برقم الهاتف هذا.',
          ));
        }
      }
      if (input.email?.isNotEmpty == true) {
        final existingByEmail =
            await _accountRepository.findAccountByEmail(input.email!);
        if (existingByEmail.valueOrNull != null) {
          return const FailureResult(ValidationFailure(
            messageAr: 'يوجد حساب مسجل مسبقاً بالبريد الإلكتروني هذا.',
          ));
        }
      }

      final id = AccountId(_idGenerator.next());
      final now = DateTime.now();
      final Account account;
      if (input.parentAccountId == null) {
        _validateRootClassification(input);
        final classification = _rootClassification(input);
        account = Account.createRoot(
          id: id,
          name: input.name,
          classification: classification,
          createdAt: now,
          isDefault: input.isDefault,
        );
      } else {
        final parentR = await _accountRepository.getById(
          AccountId(input.parentAccountId!),
        );
        if (parentR.isFailure) {
          return FailureResult(parentR.failureOrNull!);
        }
        final parent = parentR.valueOrNull!;
        account = Account.createChild(
          id: id,
          name: input.name,
          parent: parent,
          createdAt: now,
          isDefault: input.isDefault,
        );
      }

      final saved = await _accountRepository.save(account);
      if (saved.isFailure) {
        return FailureResult(saved.failureOrNull!);
      }

      final hasPartyDetails = input.phoneNumber?.isNotEmpty == true ||
          input.whatsappNumber?.isNotEmpty == true ||
          input.bankAccountInfo?.isNotEmpty == true ||
          input.partyType?.isNotEmpty == true;

      if (hasPartyDetails) {
        final partyDetails = PartyDetails(
          accountId: id,
          phoneNumber: input.phoneNumber,
          email: input.email, 
          whatsappNumber: input.whatsappNumber,
          bankAccountInfo: input.bankAccountInfo,
          partyType: input.partyType,
          currentPublicKeyHex: input.currentPublicKeyHex,
          publicKeyHistoryHex: input.publicKeyHistoryHex ?? [],
          serverAccountId: input.serverAccountId,
        );
        await _accountRepository.savePartyDetails(partyDetails);
      }

      return Success(
        CreateAccountOutput(
          accountId: account.id.value,
          name: account.name,
          natureCode: _natureCode(account),
          isRoot: account.isRoot,
          parentAccountId: account.parentId?.value,
          createdAtIso: account.createdAt.toIso8601String(),
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
        case StandardAccountClassificationKind.settlements:
          return AccountClassification.settlements;
        case StandardAccountClassificationKind.payables:
          return AccountClassification.payables;
        case StandardAccountClassificationKind.receivables:
          return AccountClassification.receivables;
        case StandardAccountClassificationKind.liquidAssets:
          return AccountClassification.liquidAssets;
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
