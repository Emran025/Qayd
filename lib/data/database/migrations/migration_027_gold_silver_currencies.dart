import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v27: seed gold (XAU) and silver (XAG) gram currencies (inactive by default).
final class Migration027GoldSilverCurrencies implements SchemaMigration {
  @override
  int get version => 27;

  @override
  Future<void> up(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Insert Gold Gram
    await db.insert(
      'currencies',
      {
        'code': 'XAU',
        'name_ar': 'جرام ذهب',
        'symbol': 'ج.ذ',
        'fractional_digits': 2,
        'is_predefined': 1,
        'is_active': 0, // Inactive by default
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Insert Silver Gram
    await db.insert(
      'currencies',
      {
        'code': 'XAG',
        'name_ar': 'جرام فضة',
        'symbol': 'ج.ف',
        'fractional_digits': 2,
        'is_predefined': 1,
        'is_active': 0, // Inactive by default
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
