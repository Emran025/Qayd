import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v16: Expand party_details for the Digital Signature Protocol.
///
/// Adds columns for:
/// - [email]: Counterparty email for identity matching (§3, §4).
/// - [current_public_key_hex]: Active Ed25519 public key (§2).
/// - [public_key_history_json]: JSON array of rotated historical keys (§5).
/// - [server_account_id]: Linkage to server Chart of Accounts (§2).
final class Migration016CounterpartyKeys implements SchemaMigration {
  @override
  int get version => 16;

  @override
  Future<void> up(Database db) async {
    await db.execute(
        'ALTER TABLE party_details ADD COLUMN email TEXT');
    await db.execute(
        'ALTER TABLE party_details ADD COLUMN current_public_key_hex TEXT');
    await db.execute(
        "ALTER TABLE party_details ADD COLUMN public_key_history_json TEXT NOT NULL DEFAULT '[]'");
    await db.execute(
        'ALTER TABLE party_details ADD COLUMN server_account_id INTEGER');

    // Enforce strict unicity at the database level for reverse-sync discovery.
    // We use partial indexes (WHERE ... IS NOT NULL) to allow accounts that
    // haven't yet been linked to an email/phone without triggering constraint failures.
    await db.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_party_email_unique ON party_details(email) WHERE email IS NOT NULL AND email != ''");
    await db.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_party_phone_unique ON party_details(phone_number) WHERE phone_number IS NOT NULL AND phone_number != ''");
  }
}
