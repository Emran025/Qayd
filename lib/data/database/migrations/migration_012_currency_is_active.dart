import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v12: add is_active and set default allowed currencies
final class Migration012CurrencyIsActive implements SchemaMigration {
  @override
  int get version => 12;

  @override
  Future<void> up(Database db) async {
    await db.execute('ALTER TABLE currencies ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1');
    await db.execute(
      "UPDATE currencies SET is_active = 0 WHERE code NOT IN ('SAR', 'YER', 'USD')",
    );
  }
}
