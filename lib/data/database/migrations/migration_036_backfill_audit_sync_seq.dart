import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Legacy audit rows created before migration 034 kept `sync_seq` NULL.
/// [SqliteAuditLogRepository.listSinceSeq] uses `sync_seq > ?`, so those rows
/// were invisible to companion initial snapshot dispatch — empty batches.
final class Migration036BackfillAuditSyncSeq implements SchemaMigration {
  @override
  int get version => 36;

  @override
  Future<void> up(Database db) async {
    final maxRow =
        await db.rawQuery('SELECT MAX(sync_seq) AS m FROM audit_logs');
    var next = (maxRow.first['m'] as int?) ?? 0;

    final rows = await db.query(
      'audit_logs',
      columns: ['id'],
      where: 'sync_seq IS NULL',
      orderBy: 'created_at ASC, id ASC',
    );

    for (final r in rows) {
      next++;
      await db.update(
        'audit_logs',
        {'sync_seq': next},
        where: 'id = ?',
        whereArgs: [r['id']],
      );
    }
  }
}
