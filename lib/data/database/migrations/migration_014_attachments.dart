import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v14: Attachments table for E2EE voucher image management.
///
/// Each row represents one encrypted image linked to a voucher.
/// The [encrypted_blob_hash] column stores the SHA-256 of the encrypted
/// blob for server-side content-blind deduplication.
final class Migration014Attachments implements SchemaMigration {
  @override
  int get version => 14;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE TABLE attachments (
  id TEXT NOT NULL PRIMARY KEY,
  voucher_id TEXT NOT NULL,
  file_name TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  encrypted_blob_hash TEXT NOT NULL,
  mime_type TEXT NOT NULL DEFAULT 'image/jpeg',
  byte_size INTEGER NOT NULL DEFAULT 0,
  source_type TEXT NOT NULL DEFAULT 'gallery',
  thumbnail_path TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (voucher_id) REFERENCES vouchers (id) ON DELETE CASCADE
)
''');
    await db.execute(
      'CREATE INDEX idx_attachments_voucher ON attachments (voucher_id)',
    );
    await db.execute(
      'CREATE INDEX idx_attachments_hash ON attachments (encrypted_blob_hash)',
    );
  }
}
