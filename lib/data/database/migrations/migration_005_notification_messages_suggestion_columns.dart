import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Adds counterparty scoping and processed flag for auto-suggestions.
final class Migration005NotificationMessagesSuggestionColumns
    implements SchemaMigration {
  @override
  int get version => 5;

  @override
  Future<void> up(Database db) async {
    await db.addColumnIfNotExists(
        'notification_messages', 'counterparty_account_id', 'TEXT');
    await db.addColumnIfNotExists(
        'notification_messages', 'processed', 'INTEGER NOT NULL',
        defaultValue: '0');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notification_messages_cp_processed '
      'ON notification_messages (counterparty_account_id, processed)',
    );
  }
}
