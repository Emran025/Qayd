import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/entities/message_template.dart';
import 'package:qayd/domain/repositories/message_template_repository.dart';
import 'package:qayd/domain/value_objects/message_template_kind.dart';

class CreateMessageTemplateUseCase {
  CreateMessageTemplateUseCase(
    this._repo,
    this._ids, {
    AuditLogService? auditLogService,
  }) : _auditLogService = auditLogService;

  final MessageTemplateRepository _repo;
  final IdGenerator _ids;
  final AuditLogService? _auditLogService;

  Future<Result<void>> call({
    required MessageTemplateKind kind,
    required String name,
    required String body,
  }) async {
    final now = DateTime.now();
    final t = MessageTemplate(
      id: _ids.next(),
      kind: kind,
      name: name.trim(),
      body: body,
      isSystem: false,
      sortOrder: 100,
      createdAt: now,
      updatedAt: now,
    );
    final result = await _repo.upsert(t);
    if (result.isSuccess) {
      await _auditLogService?.log(
        entityType: 'message_template',
        entityId: t.id,
        action: AuditAction.create,
        severity: AuditSeverity.info,
        newData: {'id': t.id, 'name': t.name},
      );
    }
    return result;
  }
}
