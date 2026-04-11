import 'package:qayd/domain/entities/audit_entry.dart';

abstract interface class AuditLogRepository {
  Future<void> save(AuditEntry entry);
  Future<List<AuditEntry>> listAll();
  Future<void> clear();
  Future<AuditEntry?> getLatest();
  Future<void> deleteAfter(DateTime timestamp);
}
