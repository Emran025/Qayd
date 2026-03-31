import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v7: Add party_details table for operational metadata linked to accounts.
final class Migration007PartyDetails implements SchemaMigration {
  @override
  int get version => 7;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE TABLE party_details (
  account_id TEXT NOT NULL PRIMARY KEY,
  phone_number TEXT,
  whatsapp_number TEXT,
  bank_account_info TEXT,
  party_type TEXT,
  FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
)
''');
  }
}
