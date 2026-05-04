import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v28: Canonical Signature Phones (Protocol v2.1).
///
/// Adds two immutable columns that permanently record the phone numbers
/// of BOTH parties **at the time the first signature was created**.
///
/// Problem solved:
///   Previously, GetVoucherDetailsUseCase reconstructed the canonical payload
///   using `signerPhone` (which can be overwritten) and `ownerPhone` (the
///   current viewer's number), causing signature verification to fail for
///   any party other than the original receiver.
///
/// Solution:
///   - `canonical_sender_phone`: Phone of Party A frozen at first signing.
///   - `canonical_receiver_phone`: Phone of Party B frozen at first signing.
///   Both columns are written once and never overwritten (enforced in entity).
final class Migration028CanonicalPhones implements SchemaMigration {
  @override
  int get version => 28;

  @override
  Future<void> up(Database db) async {
    // Party A's phone, frozen at first signing (sender's perspective).
    await db.addColumnIfNotExists(
        'vouchers', 'canonical_sender_phone', 'TEXT');

    // Party B's phone, frozen at first signing (receiver's perspective).
    await db.addColumnIfNotExists(
        'vouchers', 'canonical_receiver_phone', 'TEXT');

    // Back-fill: For existing signed vouchers, copy signerPhone → canonical_sender_phone.
    // canonical_receiver_phone cannot be inferred retroactively and stays NULL.
    // The verification logic will fall back gracefully when these are absent.
    await db.execute('''
      UPDATE vouchers
      SET canonical_sender_phone = signer_phone
      WHERE signer_phone IS NOT NULL
        AND canonical_sender_phone IS NULL
    ''');
  }
}
