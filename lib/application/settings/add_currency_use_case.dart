import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';

class AddCurrencyUseCase {
  AddCurrencyUseCase(this._repository, {AuditLogService? auditLogService})
      : _auditLogService = auditLogService;

  final CurrencyRepository _repository;
  final AuditLogService? _auditLogService;

  Future<Result<void>> call(CurrencyCode currency) async {
    final result = await _repository.save(currency, isPredefined: false);
    if (result.isSuccess) {
      await _auditLogService?.log(
        entityType: 'currency',
        entityId: currency.code,
        action: AuditAction.create,
        severity: AuditSeverity.info,
        newData: {'code': currency.code, 'name_ar': currency.nameAr},
      );
    }
    return result;
  }
}
