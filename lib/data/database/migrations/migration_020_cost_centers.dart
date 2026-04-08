import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'dart:math';

/// Schema v20: Cost and Profit Centers module.
///
/// Creates:
/// - [cost_centers]: Core entity table for all cost/profit centers.
/// - [cost_center_dimensions]: Analytical dimension tags (spatial, individual, project).
/// - [voucher_cost_centers]: Many-to-many junction: vouchers ↔ cost centers.
/// - [voucher_dimension_tags]: Optional dimension tagging per voucher-center pair.
///
/// Also seeds:
/// - Default personal expenses root account (مصروفات شخصية).
/// - Default personal revenues root account (إيرادات شخصية).
/// - Pre-defined dimension items for spatial, individual, and project axes.
final class Migration020CostCenters implements SchemaMigration {
  @override
  int get version => 20;

  @override
  Future<void> up(Database db) async {
    final now = DateTime.now().toIso8601String();

    String uuid() {
      final r = Random();
      return '${r.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0')}-'
          '${r.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0')}-'
          '4${r.nextInt(0xFFF).toRadixString(16).padLeft(3, '0')}-'
          '${(r.nextInt(0x3FFF) | 0x8000).toRadixString(16).padLeft(4, '0')}-'
          '${r.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}${r.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    }

    // ── 1. Cost Centers Table ─────────────────────────────────────────────
    await db.execute('''
CREATE TABLE cost_centers (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'cost',
  description TEXT,
  budget_minor_units INTEGER NOT NULL DEFAULT 0,
  currency_code TEXT NOT NULL DEFAULT 'SAR',
  is_active INTEGER NOT NULL DEFAULT 1,
  is_default INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  suspended_at TEXT
)
''');
    await db.execute(
      'CREATE INDEX idx_cost_centers_type ON cost_centers (type)',
    );
    await db.execute(
      'CREATE INDEX idx_cost_centers_active ON cost_centers (is_active)',
    );

    // ── 2. Dimension Categories Table ─────────────────────────────────────
    await db.execute('''
CREATE TABLE cost_center_dimension_categories (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  icon_name TEXT,
  is_default INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
)
''');

    // ── 3. Dimensions Table ───────────────────────────────────────────────
    await db.execute('''
CREATE TABLE cost_center_dimensions (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  cost_center_id TEXT,
  is_default INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  FOREIGN KEY (cost_center_id) REFERENCES cost_centers (id) ON DELETE SET NULL,
  FOREIGN KEY (category) REFERENCES cost_center_dimension_categories (id)
)
''');
    await db.execute(
      'CREATE INDEX idx_dimensions_center ON cost_center_dimensions (cost_center_id)',
    );
    await db.execute(
      'CREATE INDEX idx_dimensions_category ON cost_center_dimensions (category)',
    );

    // ── 4. Voucher ↔ Cost Center Junction ────────────────────────────────
    await db.execute('''
CREATE TABLE voucher_cost_centers (
  id TEXT NOT NULL PRIMARY KEY,
  voucher_id TEXT NOT NULL,
  cost_center_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (voucher_id) REFERENCES vouchers (id) ON DELETE CASCADE,
  FOREIGN KEY (cost_center_id) REFERENCES cost_centers (id) ON DELETE CASCADE
)
''');
    await db.execute(
      'CREATE INDEX idx_vcc_voucher ON voucher_cost_centers (voucher_id)',
    );
    await db.execute(
      'CREATE INDEX idx_vcc_center ON voucher_cost_centers (cost_center_id)',
    );
    await db.execute('''
CREATE UNIQUE INDEX idx_vcc_unique ON voucher_cost_centers (voucher_id, cost_center_id)
''');

    // ── 5. Voucher Dimension Tags ─────────────────────────────────────────
    await db.execute('''
CREATE TABLE voucher_dimension_tags (
  id TEXT NOT NULL PRIMARY KEY,
  voucher_id TEXT NOT NULL,
  cost_center_id TEXT NOT NULL,
  dimension_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (voucher_id) REFERENCES vouchers (id) ON DELETE CASCADE,
  FOREIGN KEY (cost_center_id) REFERENCES cost_centers (id) ON DELETE CASCADE,
  FOREIGN KEY (dimension_id) REFERENCES cost_center_dimensions (id) ON DELETE CASCADE
)
''');
    await db.execute(
      'CREATE INDEX idx_vdt_voucher ON voucher_dimension_tags (voucher_id)',
    );
    await db.execute(
      'CREATE INDEX idx_vdt_center ON voucher_dimension_tags (cost_center_id)',
    );

    // ── 6. Seed Default Personal Accounts ────────────────────────────────
    // Personal Expenses Root Account (مصروفات شخصية)
    await db.insert('accounts', {
      'id': uuid(),
      'name': 'مصروفات شخصية',
      'nature': 'debit',
      'parent_id': null,
      'is_default': 1,
      'is_active': 1,
      'created_at': now,
      'standard_classification': 'personalExpenses',
      'custom_classification_name': null,
      'custom_classification_nature': null,
    });

    // Personal Revenues Root Account (إيرادات شخصية)
    await db.insert('accounts', {
      'id': uuid(),
      'name': 'إيرادات شخصية',
      'nature': 'credit',
      'parent_id': null,
      'is_default': 1,
      'is_active': 1,
      'created_at': now,
      'standard_classification': 'personalRevenues',
      'custom_classification_name': null,
      'custom_classification_nature': null,
    });
  }
}

