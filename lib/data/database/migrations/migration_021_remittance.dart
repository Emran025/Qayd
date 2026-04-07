import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

final class Migration021Remittance implements SchemaMigration {
  @override
  int get version => 21;

  @override
  Future<void> up(Database db) async {
    // Add columns for Remittance Protocol to vouchers table
    await db.addColumnIfNotExists(
      'vouchers',
      'mediator_account_id',
      'TEXT',
    );
    await db.addColumnIfNotExists(
      'vouchers',
      'fee_amount_minor',
      'INTEGER',
    );

    // Provide default system accounts optionally via SQL
    // We already support auto-creation of system accounts in the app.
  }
}
