import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';

class SetBaseCurrencyUseCase {
  SetBaseCurrencyUseCase(this._repository, {AuditLogService? auditLogService})
      : _auditLogService = auditLogService;

  final CurrencyRepository _repository;
  final AuditLogService? _auditLogService;

  Future<Result<void>> call(String code) async {
    final old = await _repository.getBaseCurrencyCode();
    final result = await _repository.setBaseCurrencyCode(code);
    if (result.isSuccess) {
      await _auditLogService?.log(
        entityType: 'currency',
        entityId: code,
        action: AuditAction.update,
        severity: AuditSeverity.info,
        oldData: {'base_currency': old.valueOrNull},
        newData: {'base_currency': code},
      );
    }
    return result;
  }
}
