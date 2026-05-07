import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/entities/message_template.dart';
import 'package:qayd/domain/repositories/message_template_repository.dart';

class SaveMessageTemplateUseCase {
  SaveMessageTemplateUseCase(this._repo, {AuditLogService? auditLogService})
      : _auditLogService = auditLogService;

  final MessageTemplateRepository _repo;
  final AuditLogService? _auditLogService;

  Future<Result<void>> call(MessageTemplate template) async {
    final result = await _repo.upsert(template);
    if (result.isSuccess) {
      await _auditLogService?.log(
        entityType: 'message_template',
        entityId: template.id,
        action: AuditAction.update,
        severity: AuditSeverity.info,
        newData: {'id': template.id, 'name': template.name},
      );
    }
    return result;
  }
}
