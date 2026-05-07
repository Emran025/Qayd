import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';

class AuditSyncProcessor {
  const AuditSyncProcessor({required this.auditLogRepository});

  final AuditLogRepository auditLogRepository;

  Future<void> processBatch(List<Map<String, dynamic>> entryMaps) async {
    final existingIds = (await auditLogRepository.listAll())
        .map((e) => e.id)
        .toSet();
    for (final map in entryMaps) {
      final entry = AuditEntry.fromMap(map);
      if (!existingIds.contains(entry.id)) {
        await auditLogRepository.save(entry);
        existingIds.add(entry.id);
      }
    }
  }
}
