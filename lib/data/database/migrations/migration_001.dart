import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v1: accounts, vouchers, ledger_entries with FKs and indexes.
final class Migration001 implements SchemaMigration {
  @override
  int get version => 1;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
CREATE TABLE accounts (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  nature TEXT NOT NULL,
  parent_id TEXT,
  is_default INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  standard_classification TEXT,
  custom_classification_name TEXT,
  custom_classification_nature TEXT,
  FOREIGN KEY (parent_id) REFERENCES accounts (id) ON DELETE RESTRICT
)
''');
    await db.execute(
      'CREATE INDEX idx_accounts_parent ON accounts (parent_id)',
    );

    await db.execute('''
CREATE TABLE vouchers (
  id TEXT NOT NULL PRIMARY KEY,
  type TEXT NOT NULL,
  reference_number TEXT,
  date TEXT NOT NULL,
  amount_minor INTEGER NOT NULL,
  counterparty_id TEXT NOT NULL,
  affected_account_id TEXT NOT NULL,
  state TEXT NOT NULL,
  description TEXT,
  notes TEXT,
  tags_json TEXT NOT NULL,
  attachments_json TEXT NOT NULL,
  created_at TEXT NOT NULL,
  confirmed_at TEXT,
  settled_at TEXT,
  FOREIGN KEY (counterparty_id) REFERENCES accounts (id) ON DELETE RESTRICT,
  FOREIGN KEY (affected_account_id) REFERENCES accounts (id) ON DELETE RESTRICT
)
''');
    await db.execute('CREATE INDEX idx_vouchers_date ON vouchers (date)');
    await db.execute(
      'CREATE INDEX idx_vouchers_counterparty ON vouchers (counterparty_id)',
    );
    await db.execute('CREATE INDEX idx_vouchers_state ON vouchers (state)');

    await db.execute('''
CREATE TABLE ledger_entries (
  id TEXT NOT NULL PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  account_id TEXT NOT NULL,
  side TEXT NOT NULL,
  amount_minor INTEGER NOT NULL,
  voucher_id TEXT NOT NULL,
  date TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT,
  FOREIGN KEY (voucher_id) REFERENCES vouchers (id) ON DELETE RESTRICT
)
''');
    await db.execute(
      'CREATE INDEX idx_ledger_account ON ledger_entries (account_id)',
    );
    await db.execute(
      'CREATE INDEX idx_ledger_transaction ON ledger_entries (transaction_id)',
    );
    await db.execute(
      'CREATE INDEX idx_ledger_voucher ON ledger_entries (voucher_id)',
    );
    await db.execute('CREATE INDEX idx_ledger_date ON ledger_entries (date)');
  }
}
