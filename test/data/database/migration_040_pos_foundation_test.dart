import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/data/database/database_provider.dart';
import 'package:qayd/data/database/migrations/migration_040_pos_foundation.dart';
import 'package:qayd/data/database/migrations/migration_registry.dart';
import 'package:qayd/data/database/migrations/migration_041_pos_invoice_metadata.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('database provider targets the latest registered migration', () {
    expect(
        DatabaseProvider.schemaVersion, MigrationRegistry.ordered.last.version);
  });

  group('Migration040PosFoundation', () {
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE accounts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL
        )
      ''');
    });

    tearDown(() => db.close());

    test('creates POS structure without installing user data', () async {
      await Migration040PosFoundation().up(db);

      final tables = await db.rawQuery('''
        SELECT name FROM sqlite_master
        WHERE type = 'table' AND name LIKE 'pos_%'
        ORDER BY name
      ''');
      final tableNames = tables.map((row) => row['name'] as String).toList();

      expect(
        tableNames,
        containsAll(<String>[
          'pos_settings',
          'pos_template_installs',
          'pos_warehouses',
          'pos_products',
          'pos_product_barcodes',
          'pos_stock_lots',
          'pos_stock_movements',
          'pos_invoices',
          'pos_invoice_lines',
          'pos_payments',
          'pos_returns',
          'pos_document_sequences',
        ]),
      );
      expect(tableNames, hasLength(12));

      expect((await db.query('pos_settings')), isEmpty);
      expect((await db.query('pos_template_installs')), isEmpty);
      expect((await db.query('pos_warehouses')), isEmpty);
      expect((await db.query('accounts')), hasLength(0));
    });

    test('is safe to run twice without duplicate schema objects', () async {
      final migration = Migration040PosFoundation();

      await migration.up(db);
      await migration.up(db);

      final tables = await db.rawQuery('''
        SELECT name FROM sqlite_master
        WHERE type = 'table' AND name LIKE 'pos_%'
      ''');
      final indexes = await db.rawQuery('''
        SELECT name FROM sqlite_master
        WHERE type = 'index' AND name LIKE 'idx_pos_%'
      ''');

      expect(tables, hasLength(12));
      expect(indexes.length, greaterThanOrEqualTo(8));
    });

    test('adds invoice date and signature metadata idempotently', () async {
      await Migration040PosFoundation().up(db);
      final migration = Migration041PosInvoiceMetadata();

      await migration.up(db);
      await migration.up(db);

      final columns = await db.rawQuery('PRAGMA table_info(pos_invoices)');
      final names = columns.map((row) => row['name'] as String).toSet();
      expect(
        names,
        containsAll(<String>[
          'invoice_date',
          'signature_hex',
          'signer_public_key_hex',
          'signature_payload_hash',
          'signed_at',
        ]),
      );
      final indexes = await db.rawQuery('''
        SELECT name FROM sqlite_master
        WHERE type = 'index' AND name = 'idx_pos_invoices_invoice_date'
      ''');
      expect(indexes, hasLength(1));
    });

    test('enforces core positive-value constraints', () async {
      await Migration040PosFoundation().up(db);
      final now = DateTime.utc(2026, 1, 1).toIso8601String();

      await db.insert('pos_warehouses', {
        'id': 'warehouse-1',
        'code': 'MAIN',
        'name': 'Main',
        'created_at': now,
        'updated_at': now,
      });

      expect(
        () => db.insert('pos_products', {
          'id': 'product-1',
          'sku': 'SKU-1',
          'name': 'Invalid',
          'currency_code': 'SAR',
          'sale_price_minor': -1,
          'purchase_price_minor': 0,
          'created_at': now,
          'updated_at': now,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
