import 'package:sqflite_sqlcipher/sqflite.dart';

/// Single numbered schema step applied in order by [MigrationRegistry].
abstract interface class SchemaMigration {
  int get version;

  Future<void> up(Database db);
}

extension DatabaseMigrationUtils on Database {
  /// Checks if [columnName] exists in [tableName].
  Future<bool> hasColumn(String tableName, String columnName) async {
    final List<Map<String, dynamic>> columns =
        await rawQuery('PRAGMA table_info($tableName)');
    return columns.any((column) => column['name'] == columnName);
  }

  /// Adds [column] to [table] only if it doesn't already exist.
  Future<void> addColumnIfNotExists(
    String table,
    String column,
    String type, {
    String? defaultValue,
  }) async {
    if (!await hasColumn(table, column)) {
      final String query = 'ALTER TABLE $table ADD COLUMN $column $type${defaultValue != null ? ' DEFAULT $defaultValue' : ''}';
      await execute(query);
    }
  }
}
