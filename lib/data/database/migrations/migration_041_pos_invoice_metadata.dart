import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v41: immutable invoice date and electronic-signature metadata.
///
/// Columns are nullable at storage level so existing v40 rows can be upgraded
/// without fabricating a signature. Application restore/creation paths enforce
/// the business requirement for new posted documents.
final class Migration041PosInvoiceMetadata implements SchemaMigration {
  @override
  int get version => 41;

  @override
  Future<void> up(Database db) async {
    const additions = <String, String>{
      'invoice_date': 'TEXT',
      'signature_hex': 'TEXT',
      'signer_public_key_hex': 'TEXT',
      'signature_payload_hash': 'TEXT',
      'signed_at': 'TEXT',
    };
    final columns = await db.rawQuery('PRAGMA table_info(pos_invoices)');
    final existing =
        columns.map((row) => row['name']).whereType<String>().toSet();
    for (final entry in additions.entries) {
      if (existing.contains(entry.key)) continue;
      await db.execute(
        'ALTER TABLE pos_invoices ADD COLUMN ${entry.key} ${entry.value}',
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pos_invoices_invoice_date '
      'ON pos_invoices (invoice_date, status, document_type)',
    );
  }
}
