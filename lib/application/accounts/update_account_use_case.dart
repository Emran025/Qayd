import 'package:qayd/application/accounts/dtos/update_account_input.dart';
import 'package:qayd/application/accounts/dtos/update_account_output.dart';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/application/governance/audit_log_service.dart';

class UpdateAccountUseCase {
  UpdateAccountUseCase(
    this._accountRepository,
    this._writeGuard, {
    AuditLogService? auditLogService,
  }) : _auditLogService = auditLogService;

  final AccountRepository _accountRepository;
  final GovernanceWriteGuard _writeGuard;
  final AuditLogService? _auditLogService;

  Future<Result<UpdateAccountOutput>> call(UpdateAccountInput input) async {
    try {
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }
      final loaded =
          await _accountRepository.getById(AccountId(input.accountId));
      if (loaded.isFailure) {
        return FailureResult(loaded.failureOrNull!);
      }
      final account = loaded.valueOrNull!;
      final oldData = {'name': account.name};

      final renamed = account.rename(input.newName);
      final saved = await _accountRepository.save(renamed);

      if (saved.isSuccess) {
        await _auditLogService?.log(
          entityType: 'account',
          entityId: renamed.id.value,
          action: AuditAction.update,
          oldData: oldData,
          newData: {'name': renamed.name},
        );
      }

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
