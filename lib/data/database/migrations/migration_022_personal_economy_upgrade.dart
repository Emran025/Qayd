import 'dart:math';
import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v22: Personal Economy upgrade.
/// 
/// - Adds [metadata] column to [accounts].
/// - Creates [accrual_components] table.
/// - Seeds 11 Life Dimension categories.
final class Migration022PersonalEconomyUpgrade implements SchemaMigration {
  @override
  int get version => 22;

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

    // 1. Add metadata to accounts
    await db.execute('ALTER TABLE accounts ADD COLUMN metadata TEXT');

    // 2. Add Accrual Components table
    await db.execute('''
CREATE TABLE accrual_components (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  total_amount_minor INTEGER NOT NULL,
  currency_code TEXT NOT NULL,
  source_account_id TEXT,
  destination_account_id TEXT,
  cost_center_id TEXT,
  category_id TEXT,
  frequency TEXT NOT NULL,
  start_date TEXT NOT NULL,
  next_due_date TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  FOREIGN KEY (source_account_id) REFERENCES accounts (id) ON DELETE SET NULL,
  FOREIGN KEY (destination_account_id) REFERENCES accounts (id) ON DELETE SET NULL,
  FOREIGN KEY (cost_center_id) REFERENCES cost_centers (id) ON DELETE SET NULL
)
''');
    await db.execute(
      'CREATE INDEX idx_accrual_account ON accrual_components (account_id)',
    );
    await db.execute(
      'CREATE INDEX idx_accrual_center ON accrual_components (cost_center_id)',
    );

    // 3. Seed new Life Dimensions Categories
    final categories = [
      {'id': 'income_work', 'name': 'الدخل والعمل', 'icon': 'payments'},
      {'id': 'housing_living', 'name': 'السكن والمعيشة', 'icon': 'home'},
      {
        'id': 'nutrition_consumption',
        'name': 'التغذية والاستهلاك اليومي',
        'icon': 'restaurant'
      },
      {
        'id': 'transportation',
        'name': 'النقل والتنقل',
        'icon': 'directions_car'
      },
      {
        'id': 'health_care',
        'name': 'الصحة والعناية الشخصية',
        'icon': 'medical_services'
      },
      {
        'id': 'education_development',
        'name': 'التعليم وتنمية القدرات',
        'icon': 'school'
      },
      {
        'id': 'family_dependents',
        'name': 'الأسرة والمعالون',
        'icon': 'family_restroom'
      },
      {
        'id': 'obligations_debts',
        'name': 'الالتزامات والديون',
        'icon': 'account_balance'
      },
      {
        'id': 'investments_projects',
        'name': 'الاستثمارات والمشاريع',
        'icon': 'trending_up'
      },
      {
        'id': 'savings_reserves',
        'name': 'الادخار وبناء الاحتياطي',
        'icon': 'savings'
      },
      {
        'id': 'entertainment_lifestyle',
        'name': 'الترفيه ونمط الحياة',
        'icon': 'sports_esports'
      },
    ];

    for (final cat in categories) {
      // Check if already exists to avoid conflicts if previously seeded manually
      final existing = await db.query(
        'cost_center_dimension_categories',
        where: 'id = ?',
        whereArgs: [cat['id']],
      );
      if (existing.isEmpty) {
        await db.insert('cost_center_dimension_categories', {
          'id': cat['id'],
          'name': cat['name'],
          'icon_name': cat['icon'],
          'is_default': 1,
          'created_at': now,
        });
      }
    }

    // 4. Seed new Root Accounts for Fixed Assets
    await db.insert('accounts', {
      'id': uuid(),
      'name': 'أصول ثابتة (مهلكة)',
      'nature': 'debit',
      'parent_id': null,
      'is_default': 1,
      'is_active': 1,
      'created_at': now,
      'standard_classification': 'fixedDepreciableAssets',
      'custom_classification_name': null,
      'custom_classification_nature': null,
    });

    await db.insert('accounts', {
      'id': uuid(),
      'name': 'أصول ثابتة (ربحية)',
      'nature': 'debit',
      'parent_id': null,
      'is_default': 1,
      'is_active': 1,
      'created_at': now,
      'standard_classification': 'fixedProfitableAssets',
      'custom_classification_name': null,
      'custom_classification_nature': null,
    });
  }
}
