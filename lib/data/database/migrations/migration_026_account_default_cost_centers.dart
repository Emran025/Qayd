import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v26: Account Default Cost Centers.
///
/// Creates [account_default_cost_centers]: a junction table that links an
/// account to a list of default cost-center tags (with optional dimension IDs).
///
/// When a voucher is created and a given account is selected, the application
/// layer reads this table and pre-populates the voucher's cost-center tags.
final class Migration026AccountDefaultCostCenters implements SchemaMigration {
  @override
  int get version => 26;

  @override
  Future<void> up(Database db) async {
    // ── Account Default Cost Centers Table ────────────────────────────────
    await db.execute('''
CREATE TABLE account_default_cost_centers (
  id              TEXT NOT NULL PRIMARY KEY,
  account_id      TEXT NOT NULL,
  cost_center_id  TEXT NOT NULL,
  dimension_ids_json TEXT NOT NULL DEFAULT '[]',
  created_at      TEXT NOT NULL,
  FOREIGN KEY (account_id)     REFERENCES accounts (id)      ON DELETE CASCADE,
  FOREIGN KEY (cost_center_id) REFERENCES cost_centers (id)  ON DELETE CASCADE,
  UNIQUE (account_id, cost_center_id)
)
''');

    await db.execute(
      'CREATE INDEX idx_adcc_account ON account_default_cost_centers (account_id)',
    );
    await db.execute(
      'CREATE INDEX idx_adcc_center ON account_default_cost_centers (cost_center_id)',
    );
  }
}
