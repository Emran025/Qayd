import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/data/database/migrations/migration_040_pos_foundation.dart';
import 'package:qayd/data/repositories/sqlite_pos_activation_repository.dart';
import 'package:qayd/domain/entities/pos_template_definition.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final class _FixedIdGenerator implements IdGenerator {
  int _nextId = 0;

  @override
  String next() => 'generated-${_nextId++}';
}

void main() {
  sqfliteFfiInit();

  group('SqlitePosActivationRepository', () {
    late Database db;
    late SqlitePosActivationRepository repository;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE accounts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          nature TEXT NOT NULL,
          parent_id TEXT,
          is_default INTEGER NOT NULL,
          is_active INTEGER NOT NULL,
          is_archived INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          standard_classification TEXT,
          custom_classification_name TEXT,
          custom_classification_nature TEXT,
          metadata TEXT
        )
      ''');
      await Migration040PosFoundation().up(db);
      repository = SqlitePosActivationRepository(db, _FixedIdGenerator());
    });

    tearDown(() => db.close());

    test('installs template atomically and enables POS', () async {
      final result = await repository.installTemplate(
        template: PosTemplateDefinition.current(),
        now: DateTime.utc(2026, 1, 1),
        deviceId: 'device-a',
      );

      expect(result.isSuccess, isTrue);
      final activation = result.valueOrNull!;
      expect(activation.alreadyInstalled, isFalse);
      expect(activation.accountIdsByKey, hasLength(10));
      expect((await db.query('accounts')), hasLength(10));
      expect((await db.query('pos_warehouses')), hasLength(1));
      expect((await db.query('pos_template_installs')), hasLength(1));
      expect((await db.query('pos_settings')), hasLength(1));
      expect((await repository.isEnabled()).valueOrNull, isTrue);
    });

    test('reuses an installed template without duplicates', () async {
      final template = PosTemplateDefinition.current();
      final first = await repository.installTemplate(
        template: template,
        now: DateTime.utc(2026, 1, 1),
        deviceId: 'device-a',
      );
      final second = await repository.installTemplate(
        template: template,
        now: DateTime.utc(2026, 1, 2),
        deviceId: 'device-a',
      );

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(second.valueOrNull!.alreadyInstalled, isTrue);
      expect((await db.query('accounts')), hasLength(10));
      expect((await db.query('pos_warehouses')), hasLength(1));
      expect((await db.query('pos_template_installs')), hasLength(1));
    });

    test('disabling hides POS but preserves the installed template', () async {
      await repository.installTemplate(
        template: PosTemplateDefinition.current(),
        now: DateTime.utc(2026, 1, 1),
        deviceId: 'device-a',
      );

      final disabled = await repository.disable();

      expect(disabled.isSuccess, isTrue);
      expect((await repository.isEnabled()).valueOrNull, isFalse);
      expect((await db.query('accounts')), hasLength(10));
      expect((await db.query('pos_template_installs')), hasLength(1));
      expect((await db.query('pos_warehouses')), hasLength(1));
    });
  });
}
