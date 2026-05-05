import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// v032 — Adds `severity` column and performance indexes to audit_logs.
///
/// Indexes created:
///  * `idx_audit_logs_created_at`  — fast timeline queries.
///  * `idx_audit_logs_is_undone`   — fast HEAD lookup (WHERE is_undone = 0).
///  * `idx_audit_logs_batch_id`    — fast batch undo/redo.
///  * `idx_audit_logs_entity`      — fast per-entity history.
final class Migration032AuditLogSeverityAndIndexes implements SchemaMigration {
  @override
  int get version => 32;

  @override
  Future<void> up(Database db) async {
    // Add severity column (defaults to 'info' for existing rows).
    await db.execute(
      "ALTER TABLE audit_logs ADD COLUMN severity TEXT NOT NULL DEFAULT 'info'",
    );

    // Performance indexes.
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs (created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_is_undone ON audit_logs (is_undone)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_batch_id ON audit_logs (batch_id) WHERE batch_id IS NOT NULL',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs (entity_type, entity_id)',
    );
  }
}
