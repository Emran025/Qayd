import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Fiscal periods and signed per-account snapshots for brought-forward balances (Qayd V3).
final class Migration035FiscalPeriods implements SchemaMigration {
  @override
  int get version => 35;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE TABLE fiscal_periods (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('open', 'closing', 'closed')) DEFAULT 'open',
  closed_at TEXT,
  closing_voucher_id TEXT,
  aggregate_snapshot_hash TEXT,
  aggregate_signature_hex TEXT,
  signer_public_key_hex TEXT,
  FOREIGN KEY (closing_voucher_id) REFERENCES vouchers (id) ON DELETE SET NULL
)
''');
    await db.execute(
      'CREATE INDEX idx_fiscal_periods_status ON fiscal_periods (status)',
    );
    await db.execute(
      'CREATE INDEX idx_fiscal_periods_start ON fiscal_periods (start_date)',
    );

    await db.execute('''
CREATE TABLE account_snapshots (
  id TEXT NOT NULL PRIMARY KEY,
  period_id TEXT NOT NULL,
  account_id TEXT NOT NULL,
  balance_minor_units INTEGER NOT NULL,
  currency_code TEXT NOT NULL,
  row_hash TEXT NOT NULL,
  FOREIGN KEY (period_id) REFERENCES fiscal_periods (id) ON DELETE CASCADE,
  FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
  UNIQUE (period_id, account_id, currency_code)
)
''');
    await db.execute(
      'CREATE INDEX idx_account_snapshots_period ON account_snapshots (period_id)',
    );
    await db.execute(
      'CREATE INDEX idx_account_snapshots_account ON account_snapshots (account_id)',
    );
  }
}
