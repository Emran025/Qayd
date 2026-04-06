import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v8: Dual-Party Signatures and Digital Identity Protocol.
///
/// Refactored to implement the dual-signature protocol (v2.0) from version 8.
/// Adds dual status, dual signatures, lifecycle tracking, and signer metadata.
final class Migration008VoucherSignatures implements SchemaMigration {
  @override
  int get version => 8;

  @override
  Future<void> up(Database db) async {
    // 1. Digital identity mapping
    await db.addColumnIfNotExists('vouchers', 'signer_phone', 'TEXT');

    // 2. Dual agreement statuses
    await db.addColumnIfNotExists('vouchers', 'sender_status', 'TEXT',
        defaultValue: "'accepted'");
    await db.addColumnIfNotExists('vouchers', 'receiver_status', 'TEXT',
        defaultValue: "'under_request'");

    // 3. Dual signatures and public keys
    await db.addColumnIfNotExists(
        'vouchers', 'sender_signature_hex', 'TEXT');
    await db.addColumnIfNotExists(
        'vouchers', 'receiver_signature_hex', 'TEXT');
    await db.addColumnIfNotExists(
        'vouchers', 'sender_public_key_hex', 'TEXT');
    await db.addColumnIfNotExists(
        'vouchers', 'receiver_public_key_hex', 'TEXT');

    // 4. High-level lifecycle status (for aggregate balance tracking)
    await db.addColumnIfNotExists('vouchers', 'lifecycle_status', 'TEXT',
        defaultValue: "'draft'");

    // Historical sync for existing vouchers (if any)
    await db.execute('''
      UPDATE vouchers 
      SET sender_status = 'accepted', 
          receiver_status = 'under_request',
          lifecycle_status = CASE 
            WHEN state = 'confirmed' THEN 'confirmed'
            WHEN state = 'settled' THEN 'confirmed'
            WHEN state = 'withdrawn' THEN 'withdrawn'
            ELSE 'draft'
          END
    ''');
  }
}
