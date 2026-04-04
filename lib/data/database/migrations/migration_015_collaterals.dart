import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v15: Collaterals and revaluation audit trail tables.
///
/// The [collaterals] table stores collateral records linked one-to-one
/// with vouchers. The [collateral_revaluations] table maintains a
/// chronological log of all value/expiry changes for auditability.
final class Migration015Collaterals implements SchemaMigration {
  @override
  int get version => 15;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE TABLE collaterals (
  id TEXT NOT NULL PRIMARY KEY,
  voucher_id TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  estimated_value_minor INTEGER NOT NULL,
  currency_code TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  expiry_date TEXT,
  images_json TEXT,
  encrypted_metadata TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (voucher_id) REFERENCES vouchers (id) ON DELETE CASCADE
)
''');
    await db.execute(
      'CREATE INDEX idx_collaterals_voucher ON collaterals (voucher_id)',
    );
    await db.execute(
      'CREATE INDEX idx_collaterals_status ON collaterals (status)',
    );
    await db.execute(
      'CREATE INDEX idx_collaterals_expiry ON collaterals (expiry_date)',
    );

    await db.execute('''
CREATE TABLE collateral_revaluations (
  id TEXT NOT NULL PRIMARY KEY,
  collateral_id TEXT NOT NULL,
  old_value_minor INTEGER NOT NULL,
  new_value_minor INTEGER NOT NULL,
  old_expiry_date TEXT,
  new_expiry_date TEXT,
  reason TEXT NOT NULL,
  evaluated_at TEXT NOT NULL,
  FOREIGN KEY (collateral_id) REFERENCES collaterals (id) ON DELETE CASCADE
)
''');
    await db.execute(
      'CREATE INDEX idx_revaluations_collateral ON collateral_revaluations (collateral_id)',
    );
  }
}
