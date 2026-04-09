import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class Migration013TransactionFees implements SchemaMigration {
  @override
  int get version => 13;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE transaction_fees (
        id TEXT PRIMARY KEY NOT NULL,
        amount_minor_units INTEGER NOT NULL,
        currency_code TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Add index for fast querying of active fee
    await db.execute('''
      CREATE INDEX idx_transaction_fees_active ON transaction_fees(is_active)
    ''');
  }
}
