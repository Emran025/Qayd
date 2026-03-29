import 'package:sqflite_sqlcipher/sqflite.dart';

/// Single numbered schema step applied in order by [MigrationRegistry].
abstract interface class SchemaMigration {
  int get version;

  Future<void> up(Database db);
}
