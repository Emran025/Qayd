import 'package:qayd/application/accounts/dtos/update_account_input.dart';
import 'package:qayd/application/accounts/dtos/update_account_output.dart';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';

class UpdateAccountUseCase {
  UpdateAccountUseCase(this._accountRepository, this._writeGuard);

  final AccountRepository _accountRepository;
  final GovernanceWriteGuard _writeGuard;

  Future<Result<UpdateAccountOutput>> call(UpdateAccountInput input) async {
    try {
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }
      final loaded = await _accountRepository.getById(AccountId(input.accountId));
      if (loaded.isFailure) {
        return FailureResult(loaded.failureOrNull!);
      }
      final account = loaded.valueOrNull!;
      final renamed = account.rename(input.newName);
      final saved = await _accountRepository.save(renamed);
      return saved.fold(
        (f) => FailureResult(f),
        (_) => Success(
          UpdateAccountOutput(
            accountId: renamed.id.value,
            name: renamed.name,
          ),
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
