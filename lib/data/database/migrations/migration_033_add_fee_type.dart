import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class Migration033AddFeeType implements SchemaMigration {
  @override
  int get version => 33;

  @override
  Future<void> up(Database db) async {
    // 1. Add 'type' column to transaction_fees table
    await db.execute(
        'ALTER TABLE transaction_fees ADD COLUMN type TEXT NOT NULL DEFAULT "tripartite"');

    // 2. Add 'calculation_type' column
    await db.execute(
        'ALTER TABLE transaction_fees ADD COLUMN calculation_type TEXT NOT NULL DEFAULT "fixed"');

    // 3. Drop the old index if it exists and create a composite index for type and activity
    await db.execute('DROP INDEX IF EXISTS idx_transaction_fees_active');
    await db.execute(
        'CREATE INDEX idx_transaction_fees_active_type ON transaction_fees(type, is_active)');
  }
}
