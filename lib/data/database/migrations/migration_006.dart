import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v6: currencies table, base_currency configuration, and multi-currency support in vouchers/ledger.
final class Migration006 implements SchemaMigration {
  @override
  int get version => 6;

  @override
  Future<void> up(Database db) async {
    // 1. Create currencies table
    await db.execute('''
CREATE TABLE currencies (
  code TEXT NOT NULL PRIMARY KEY,
  name_ar TEXT NOT NULL,
  symbol TEXT NOT NULL,
  fractional_digits INTEGER NOT NULL DEFAULT 2,
  is_predefined INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
)
''');

    // 2. Seed predefined regional currencies
    for (final c in PredefinedCurrencies.all) {
      await db.insert('currencies', {
        'code': c.code,
        'name_ar': c.nameAr,
        'symbol': c.symbol,
        'fractional_digits': c.fractionalDigits,
        'is_predefined': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // 3. Create app_settings table for base currency configuration
    await db.execute('''
CREATE TABLE app_settings (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
)
''');
    await db.insert('app_settings', {
      'key': 'base_currency_code',
      'value': 'YER',
    });

    // 4. Add currency_code column to vouchers
    // Note: SQLite doesn't support NOT NULL column additions easily; we'll add it and then update.
    await db.addColumnIfNotExists('vouchers', 'currency_code', 'TEXT');
    await db.execute(
      "UPDATE vouchers SET currency_code = 'YER' WHERE currency_code IS NULL"
    );

    // 5. Add currency_code column to ledger_entries
    await db.addColumnIfNotExists('ledger_entries', 'currency_code', 'TEXT');
    await db.execute(
      "UPDATE ledger_entries SET currency_code = 'YER' WHERE currency_code IS NULL"
    );

    // 6. Create indexes for new columns
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_vouchers_currency ON vouchers (currency_code)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ledger_currency ON ledger_entries (currency_code)');
  }
}
