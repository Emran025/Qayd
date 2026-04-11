import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qayd/data/database/database_encryption_key_provider.dart';
import 'package:qayd/data/database/migrations/migration_registry.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Opens the encrypted SQLite database and applies migrations.
abstract final class DatabaseProvider {
  static const int schemaVersion = 24;

  static const String databaseFileName = 'qayd_finance.db';

  /// Path to the encrypted SQLite file (same path used by [open]).
  static Future<String> databaseFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, databaseFileName);
  }

  static Future<Database> open({
    required DatabaseEncryptionKeyProvider keyProvider,
  }) async {
    final path = await databaseFilePath();
    final key = await keyProvider.obtainKey();
    return openDatabase(
      path,
      version: schemaVersion,
      password: key,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await MigrationRegistry.applyFromTo(
          db,
          fromVersion: 0,
          toVersion: version,
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await MigrationRegistry.applyFromTo(
          db,
          fromVersion: oldVersion,
          toVersion: newVersion,
        );
      },
    );
  }
}
