import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Backfills audit log CREATE entries for accounts that were seeded directly
/// via migrations (e.g., Migration011DefaultAccounts) and therefore lack audit entries.
/// This ensures they are dispatched to companion devices during the initial snapshot sync,
/// preventing FOREIGN KEY constraint failures when child accounts are synced.
final class Migration039BackfillDefaultAccountsAudit implements SchemaMigration {
  @override
  int get version => 39;

  @override
  Future<void> up(Database db) async {
    // Find all accounts that do not have a CREATE audit entry
    final unloggedAccounts = await db.rawQuery('''
      SELECT id, created_at FROM accounts 
      WHERE id NOT IN (
        SELECT entity_id FROM audit_logs 
        WHERE entity_type IN ('account', 'accounts') AND action = 'create'
      )
    ''');

    if (unloggedAccounts.isEmpty) return;

    final maxRow = await db.rawQuery('SELECT MAX(sync_seq) AS m FROM audit_logs');
    var nextSyncSeq = (maxRow.first['m'] as int?) ?? 0;

    for (final account in unloggedAccounts) {
      nextSyncSeq++;
      
      final String auditId = const Uuid().v4();
      // We use the account's creation time so it looks authentic in the audit log
      final String createdAt = account['created_at'] as String;
      
      await db.insert('audit_logs', {
        'id': auditId,
        'entity_type': 'account',
        'entity_id': account['id'],
        'action': 'create',
        'severity': 'info',
        'is_undone': 0,
        'created_at': createdAt,
        'sync_seq': nextSyncSeq,
      });
    }
  }
}
