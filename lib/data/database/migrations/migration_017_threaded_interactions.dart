import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v17: Threaded Financial Interactions — adds origin_voucher_id,
/// rejection_reason, and withdrawn_at to vouchers table.
final class Migration017ThreadedInteractions implements SchemaMigration {
  @override
  int get version => 17;

  @override
  Future<void> up(Database db) async {
    // Add origin_voucher_id for the "Reply" mechanism (reversals, corrections, settlements)
    await db.addColumnIfNotExists('vouchers', 'origin_voucher_id', 'TEXT');

    // Add rejection_reason for corrective resubmission flow
    await db.addColumnIfNotExists('vouchers', 'rejection_reason', 'TEXT');

    // Add withdrawn_at timestamp for non-destructive withdrawal state
    await db.addColumnIfNotExists('vouchers', 'withdrawn_at', 'TEXT');

    // Index origin_voucher_id for efficient thread queries
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vouchers_origin ON vouchers (origin_voucher_id)',
    );
  }
}
