import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


final class UpdateCostCenterUseCase {
  const UpdateCostCenterUseCase(this._repository, {AuditLogService? auditLogService})
      : _auditLogService = auditLogService;

  final CostCenterRepository _repository;
  final AuditLogService? _auditLogService;

  Future<Result<void>> call({
    required String id,
    String? name,
    CostCenterType? type,
    String? currencyCode,
    String? description,
    int? budgetMinorUnits,
    bool? isActive,
  }) async {
    final existingResult = await _repository.getById(id);
    return existingResult.fold(
      (f) => FailureResult(f),
      (existing) async {
        if (existing == null) {
          return  FailureResult(
            ValidationFailure(
              messageAr: AppStrings.costCenterDoesNot,
              code: 'cost_center_not_found',
            ),
          );
        }

        final updated = existing.copyWith(
          name: name ?? existing.name,
          type: type ?? existing.type,
          currencyCode: currencyCode ?? existing.currencyCode,
          description: description ?? existing.description,
          budgetMinorUnits: budgetMinorUnits ?? existing.budgetMinorUnits,
          isActive: isActive ?? existing.isActive,
        );

        final saveResult = await _repository.save(updated);
        if (saveResult.isSuccess) {
          await _auditLogService?.log(
            entityType: 'cost_center',
            entityId: updated.id,
            action: AuditAction.update,
            severity: AuditSeverity.info,
            oldData: {'id': existing.id, 'is_active': existing.isActive, 'name': existing.name},
            newData: {'id': updated.id, 'is_active': updated.isActive, 'name': updated.name},
          );
        }
        return saveResult;
      },
    );
  }
}
