import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// FTS5 index for voucher full-text search (id, reference, description, notes).
final class Migration002VoucherFts implements SchemaMigration {
  @override
  int get version => 2;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE VIRTUAL TABLE IF NOT EXISTS vouchers_fts USING fts5(
  body,
  tokenize = 'unicode61'
)
''');

    await db.execute('''
CREATE TRIGGER IF NOT EXISTS vouchers_fts_ai AFTER INSERT ON vouchers BEGIN
  INSERT INTO vouchers_fts(rowid, body) VALUES (
    new.rowid,
    new.id || ' ' || ifnull(new.reference_number, '') || ' ' ||
    ifnull(new.description, '') || ' ' || ifnull(new.notes, '')
  );
END
''');

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

    await db.execute('''
INSERT INTO vouchers_fts(rowid, body)
SELECT
  rowid,
  id || ' ' || ifnull(reference_number, '') || ' ' ||
  ifnull(description, '') || ' ' || ifnull(notes, '')
FROM vouchers
''');
  }
}
