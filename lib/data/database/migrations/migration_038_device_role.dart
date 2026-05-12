import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

final class Migration038DeviceRole implements SchemaMigration {
  @override
  int get version => 38;

  @override
  Future<void> up(Database db) async {
    await db.addColumnIfNotExists('device_sessions', 'role', 'TEXT');
  }
}
