import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


final class ActivateCostCenterUseCase {
  const ActivateCostCenterUseCase(this._repository, {AuditLogService? auditLogService})
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
        final activated = center.activate();
        final saveResult = await _repository.save(activated);
        if (saveResult.isSuccess) {
          await _auditLogService?.log(
            entityType: 'cost_center',
            entityId: activated.id,
            action: AuditAction.update,
            severity: AuditSeverity.info,
            oldData: {'id': center.id, 'is_active': center.isActive},
            newData: {'id': activated.id, 'is_active': activated.isActive},
          );
        }
        return saveResult;
      },
    );
  }
}
