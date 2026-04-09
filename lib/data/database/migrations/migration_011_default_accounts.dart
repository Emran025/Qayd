import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'dart:math';

/// Schema v11: Seed default root accounts (Cash, Accounts Payable, Accounts Receivable)
final class Migration011DefaultAccounts implements SchemaMigration {
  @override
  int get version => 11;

  @override
  Future<void> up(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Simple fast UUID v4 equivalent for SQLite insertion since we don't need cryptographic randomness for default account IDs here.
    String uuid() {
      final r = Random();
      return '${r.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0')}-'
          '${r.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0')}-'
          '4${r.nextInt(0xFFF).toRadixString(16).padLeft(3, '0')}-'
          '${(r.nextInt(0x3FFF) | 0x8000).toRadixString(16).padLeft(4, '0')}-'
          '${r.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}${r.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    }

    // Cash account (cannot be deleted, is_default = 1)
    await db.insert('accounts', {
      'id': uuid(),
      'name': 'الصندوق', // Cash account
      'nature': 'debit',
      'parent_id': null,
      'is_default': 1,
      'is_active': 1,
      'created_at': now,
      'standard_classification': 'liquidAssets',
      'custom_classification_name': null,
      'custom_classification_nature': null,
    });

    // Accounts Payable (can be deleted, is_default = 0)
    await db.insert('accounts', {
      'id': uuid(),
      'name': 'ذمم دائنة', // Accounts payable
      'nature': 'credit',
      'parent_id': null,
      'is_default': 0,
      'is_active': 1,
      'created_at': now,
      'standard_classification': 'payables',
      'custom_classification_name': null,
      'custom_classification_nature': null,
    });

    // Accounts Receivable (can be deleted, is_default = 0)
    await db.insert('accounts', {
      'id': uuid(),
      'name': 'ذمم مدينة', // Accounts receivable
      'nature': 'debit',
      'parent_id': null,
      'is_default': 0,
      'is_active': 1,
      'created_at': now,
      'standard_classification': 'receivables',
      'custom_classification_name': null,
      'custom_classification_nature': null,
    });
  }
}
