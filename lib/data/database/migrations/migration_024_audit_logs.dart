import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

final class Migration024AuditLogs implements SchemaMigration {
  @override
  int get version => 24;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS audit_logs (
    id TEXT PRIMARY KEY,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    action TEXT NOT NULL,
    old_data TEXT,
    new_data TEXT,
    created_at TEXT NOT NULL
);
''');
  }
}
