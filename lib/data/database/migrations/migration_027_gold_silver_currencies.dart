import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


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
        'name_ar': AppStringsAr.aGramOfGold,
        'symbol': AppStringsAr.cD,
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
        'name_ar': AppStringsAr.gramOfSilver,
        'symbol': AppStringsAr.dry,
        'fractional_digits': 2,
        'is_predefined': 1,
        'is_active': 0, // Inactive by default
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
