import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/message_template_repository.dart';

class DeleteMessageTemplateUseCase {
  DeleteMessageTemplateUseCase(this._repo, {AuditLogService? auditLogService})
      : _auditLogService = auditLogService;

  final MessageTemplateRepository _repo;
  final AuditLogService? _auditLogService;

  Future<Result<void>> call(String templateId) async {
    final existing = await _repo.getById(templateId);
    final result = await _repo.deleteById(templateId);
    if (result.isSuccess) {
      await _auditLogService?.log(
        entityType: 'message_template',
        entityId: templateId,
        action: AuditAction.delete,
        severity: AuditSeverity.warning,
        oldData: {
          'id': templateId,
          'name': existing.valueOrNull?.name,
        },
      );
    }
    return result;
  }
}
