import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v18: Local Outbox — persists all local mutations until delivery
/// acknowledgment, supporting both server and P2P sync transports.
final class Migration018Outbox implements SchemaMigration {
  @override
  int get version => 18;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE TABLE outbox (
  id TEXT NOT NULL PRIMARY KEY,
  event_type TEXT NOT NULL,
  voucher_id TEXT,
  counterparty_account_id TEXT NOT NULL,
  encrypted_payload TEXT NOT NULL,
  state TEXT NOT NULL DEFAULT 'pending',
  transport TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  delivered_at TEXT,
  FOREIGN KEY (voucher_id) REFERENCES vouchers (id) ON DELETE SET NULL
)
''');
    await db.execute(
      'CREATE INDEX idx_outbox_state ON outbox (state)',
    );
    await db.execute(
      'CREATE INDEX idx_outbox_counterparty ON outbox (counterparty_account_id)',
    );
  }
}
