import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:qayd/application/governance/audit_log_service.dart';

class AuditSyncProcessor {
  const AuditSyncProcessor({
    required this.auditLogRepository,
    this.auditLogService,
  });

  final AuditLogRepository auditLogRepository;
  final AuditLogService? auditLogService;

  Future<void> processBatch(List<Map<String, dynamic>> entryMaps) async {
    final existingIds =
        (await auditLogRepository.listAll()).map((e) => e.id).toSet();
    for (final map in entryMaps) {
      final rawEntry = AuditEntry.fromMap(map);
      final entry = rawEntry.actorId == null
          ? rawEntry.copyWith(actorId: 'sync:remote')
          : rawEntry;
      if (!existingIds.contains(entry.id)) {
        await auditLogService?.replaySyncedEntry(entry);
        await auditLogRepository.save(entry);
        existingIds.add(entry.id);
      }
    }
  }
}
