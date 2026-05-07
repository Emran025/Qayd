import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';

class ToggleCurrencyStatusUseCase {
  ToggleCurrencyStatusUseCase(this._repository,
      {AuditLogService? auditLogService})
      : _auditLogService = auditLogService;

  final CurrencyRepository _repository;
  final AuditLogService? _auditLogService;

  Future<Result<void>> call(String code, bool isActive) async {
    final old = await _repository.getByCode(code);
    final result = await _repository.toggleActiveStatus(code, isActive);
    if (result.isSuccess) {
      await _auditLogService?.log(
        entityType: 'currency',
        entityId: code,
        action: AuditAction.update,
        severity: AuditSeverity.info,
        oldData: {'code': code, 'is_active': old.valueOrNull?.isActive},
        newData: {'code': code, 'is_active': isActive},
      );
    }
    return result;
  }
}
