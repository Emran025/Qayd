import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// v031 — Adds batch_id, actor_id and is_undone columns needed by the
/// undo/redo engine introduced in the initial audit-log overhaul.
final class Migration031AuditLogEnhancements implements SchemaMigration {
  @override
  int get version => 31;

  @override
  Future<void> up(Database db) async {
    await db.execute(
        'ALTER TABLE audit_logs ADD COLUMN batch_id TEXT');
    await db.execute(
        'ALTER TABLE audit_logs ADD COLUMN actor_id TEXT');
    await db.execute(
        'ALTER TABLE audit_logs ADD COLUMN is_undone INTEGER NOT NULL DEFAULT 0');
  }
}
