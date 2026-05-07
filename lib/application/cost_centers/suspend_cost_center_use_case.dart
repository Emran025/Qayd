import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


final class SuspendCostCenterUseCase {
  const SuspendCostCenterUseCase(this._repository, {AuditLogService? auditLogService})
      : _auditLogService = auditLogService;

  final CostCenterRepository _repository;
  final AuditLogService? _auditLogService;

  Future<Result<void>> call(String id) async {
    final result = await _repository.getById(id);
    return result.fold(
      (f) => FailureResult(f),
      (center) async {
        if (center == null) {
          return  FailureResult(
            ValidationFailure(
              messageAr: AppStrings.costCenterDoesNot,
              code: 'cost_center_not_found',
            ),
          );
        }
        final suspended = center.suspend(DateTime.now());
        final saveResult = await _repository.save(suspended);
        if (saveResult.isSuccess) {
          await _auditLogService?.log(
            entityType: 'cost_center',
            entityId: suspended.id,
            action: AuditAction.update,
            severity: AuditSeverity.warning,
            oldData: {'id': center.id, 'is_active': center.isActive},
            newData: {'id': suspended.id, 'is_active': suspended.isActive},
          );
        }
        return saveResult;
      },
    );
  }
}
