import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Fixes FTS5 triggers that caused SQL logic error due to using 
/// external-content delete syntax on a normal FTS table.
final class Migration023FixFtsTriggers implements SchemaMigration {
  @override
  int get version => 23;

  @override
  Future<void> up(Database db) async {
    // Drop the old faulty triggers
    await db.execute('DROP TRIGGER IF EXISTS vouchers_fts_ad;');
    await db.execute('DROP TRIGGER IF EXISTS vouchers_fts_au;');

    // Recreate them with proper syntax for standard FTS5
    await db.execute('''
CREATE TRIGGER IF NOT EXISTS vouchers_fts_ad AFTER DELETE ON vouchers BEGIN
  DELETE FROM vouchers_fts WHERE rowid = old.rowid;
END
''');

    await db.execute('''
CREATE TRIGGER IF NOT EXISTS vouchers_fts_au AFTER UPDATE ON vouchers BEGIN
  UPDATE vouchers_fts SET body = new.id || ' ' || ifnull(new.reference_number, '') || ' ' ||
    ifnull(new.description, '') || ' ' || ifnull(new.notes, '')
  WHERE rowid = old.rowid;
END
''');
  }
}
