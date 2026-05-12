import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Adds [is_inbound] flag to the [vouchers] table.
///
/// A voucher received from the counterparty via sync (an incoming claim) is
/// stored with this flag = 1.  Vouchers created locally are flag = 0.
///
/// Previously, [isCreator] was inferred from `affectedAccountId == myAccountId`,
/// which was always TRUE for inbound claims because `_inboundVoucherClaim` sets
/// `affectedAccountId` to the local fund account.  This caused inbound vouchers
/// to appear as if the local user had created them, hiding accept/reject buttons
/// and showing incorrect UI states (e.g. "draft" counted as mine).
///
/// Backfill heuristic:
///   - If sender_signature_hex IS NOT NULL AND receiver_status = 'underRequest'
///     → the counterparty signed it and it is waiting for us → mark is_inbound = 1
///   - All other rows default to 0 (locally created).
final class Migration037VoucherIsInbound implements SchemaMigration {
  @override
  int get version => 37;

  @override
  Future<void> up(Database db) async {
    // 1. Add column with safe default.
    await db.execute(
      'ALTER TABLE vouchers ADD COLUMN is_inbound INTEGER NOT NULL DEFAULT 0',
    );

    // 2. Backfill: rows where the counterparty signed AND we haven't responded
    //    yet are the clearest sign of an inbound claim.
    await db.execute('''
      UPDATE vouchers
      SET is_inbound = 1
      WHERE sender_signature_hex IS NOT NULL
        AND receiver_status = 'underRequest'
    ''');
  }
}
