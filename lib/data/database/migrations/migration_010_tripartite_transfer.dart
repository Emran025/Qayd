import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v10: Tripartite intermediary transfer columns on [vouchers].
///
/// Enables a mediator (C) to broker transfers between two external parties
/// (A → C → B) via cryptographically linked voucher pairs.
///
/// - [transfer_group_id]: UUID linking the receipt (A→C) and payment (C→B).
/// - [tripartite_role]: 'intermediary_receipt' | 'intermediary_payment' | NULL.
/// - [linked_party_id]: FK to accounts — the counterpart in the chain
///   (e.g. on the A→C receipt, this stores B's account ID).
/// - [is_contingent]: 1 = blocked until its parent voucher is verified/confirmed.
final class Migration010TripartiteTransfer implements SchemaMigration {
  @override
  int get version => 10;

  @override
  Future<void> up(Database db) async {
    await db.execute(
        'ALTER TABLE vouchers ADD COLUMN transfer_group_id TEXT');
    await db.execute(
        'ALTER TABLE vouchers ADD COLUMN tripartite_role TEXT');
    await db.execute(
        'ALTER TABLE vouchers ADD COLUMN linked_party_id TEXT');
    await db.execute(
        'ALTER TABLE vouchers ADD COLUMN is_contingent INTEGER NOT NULL DEFAULT 0');

    // Index for fast lookup of paired vouchers within a transfer group.
    await db.execute(
        'CREATE INDEX idx_vouchers_transfer_group ON vouchers (transfer_group_id)');
  }
}
