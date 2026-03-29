import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v4: raw notification message payloads for future auto-suggestion engine.
final class Migration004NotificationMessages implements SchemaMigration {
  @override
  int get version => 4;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE TABLE notification_messages (
  id TEXT NOT NULL PRIMARY KEY,
  body_text TEXT NOT NULL,
  channel TEXT,
  context_kind TEXT,
  context_ref TEXT,
  created_at TEXT NOT NULL,
  raw_payload_json TEXT
)
''');
    await db.execute(
      'CREATE INDEX idx_notification_messages_created ON notification_messages (created_at)',
    );
  }
}
