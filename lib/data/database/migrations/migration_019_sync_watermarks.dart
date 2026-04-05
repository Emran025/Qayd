import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v19: Per-counterparty sync watermark table — tracks last sync
/// timestamp and read position for each counterparty, enabling delta sync.
final class Migration019SyncWatermarks implements SchemaMigration {
  @override
  int get version => 19;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE TABLE sync_watermarks (
  counterparty_account_id TEXT NOT NULL PRIMARY KEY,
  last_synced_at TEXT NOT NULL,
  last_opened_voucher_id TEXT,
  transport TEXT NOT NULL DEFAULT 'server'
)
''');
  }
}
