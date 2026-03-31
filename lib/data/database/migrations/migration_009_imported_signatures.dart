import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v9: Track imported signatures to prevent duplicate imports.
///
/// When Party B receives a signed receipt (via QR, SMS, or manual paste),
/// the signature hash is recorded here. Future imports of the same
/// signature are rejected — preventing replay attacks.
final class Migration009ImportedSignatures implements SchemaMigration {
  @override
  int get version => 9;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE TABLE imported_signatures (
  id TEXT NOT NULL PRIMARY KEY,
  signature_hash TEXT UNIQUE NOT NULL,
  voucher_id TEXT NOT NULL,
  imported_at TEXT NOT NULL,
  source TEXT NOT NULL,
  FOREIGN KEY (voucher_id) REFERENCES vouchers(id) ON DELETE CASCADE
)
''');
    await db.execute(
        'CREATE INDEX idx_imported_sig_hash ON imported_signatures(signature_hash)');
  }
}
