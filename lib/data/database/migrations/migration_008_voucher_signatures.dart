import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v8: Add digital signature columns to the vouchers table.
///
/// These columns enable cryptographic receipt verification:
/// - [signature_hex]: The Ed25519 signature (128 hex chars).
/// - [signer_public_key_hex]: Public key of the signer (64 hex chars).
/// - [signature_status]: unsigned | signed | verified | invalid.
/// - [signer_phone]: Phone number of the signing party (for matching).
final class Migration008VoucherSignatures implements SchemaMigration {
  @override
  int get version => 8;

  @override
  Future<void> up(Database db) async {
    await db.execute(
        'ALTER TABLE vouchers ADD COLUMN signature_hex TEXT');
    await db.execute(
        'ALTER TABLE vouchers ADD COLUMN signer_public_key_hex TEXT');
    await db.execute(
        "ALTER TABLE vouchers ADD COLUMN signature_status TEXT NOT NULL DEFAULT 'unsigned'");
    await db.execute(
        'ALTER TABLE vouchers ADD COLUMN signer_phone TEXT');
  }
}
