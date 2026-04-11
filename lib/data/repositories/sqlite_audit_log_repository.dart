import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class SqliteAuditLogRepository implements AuditLogRepository {
  final Database _db;

  SqliteAuditLogRepository(this._db);

  @override
  Future<void> save(AuditEntry entry) async {
    await _db.insert('audit_logs', entry.toMap());
  }

  @override
  Future<List<AuditEntry>> listAll() async {
    final list = await _db.query('audit_logs', orderBy: 'created_at DESC');
    return list.map(AuditEntry.fromMap).toList();
  }

  @override
  Future<void> clear() async {
    await _db.delete('audit_logs');
  }

  @override
  Future<AuditEntry?> getLatest() async {
    final list = await _db.query('audit_logs', orderBy: 'created_at DESC', limit: 1);
    if (list.isEmpty) return null;
    return AuditEntry.fromMap(list.first);
  }

  @override
  Future<void> deleteAfter(DateTime timestamp) async {
    await _db.delete(
      'audit_logs',
      where: 'created_at > ?',
      whereArgs: [timestamp.toIso8601String()],
    );
  }
}
