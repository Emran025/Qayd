import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Adds `is_archived` flag to the `accounts` table.
///
/// Archived accounts (balance == 0) are hidden from active lists, dropdowns,
/// and financial reports. They can be restored from a dedicated archive page.
class Migration025AccountArchive implements SchemaMigration {
  @override
  int get version => 25;

  @override
  Future<void> up(Database db) async {
    await db.addColumnIfNotExists(
      'accounts',
      'is_archived',
      'INTEGER',
      defaultValue: '0',
    );

    // Index for fast filtering of archived vs active accounts.
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_accounts_is_archived
      ON accounts(is_archived)
    ''');
  }
}
