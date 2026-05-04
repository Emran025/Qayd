import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v29: Add plaintext routing headers to the outbox table.
///
/// §5.C — Flexible Routing: The outbox must capture receiver routing hints
/// at the moment of voucher creation (when identity discovery runs).
/// These hints are stored OUTSIDE the encrypted payload so the server can
/// route the node without decryption.
///
/// Columns added:
///   - receiver_phone      : E.164 phone number (primary routing hint)
///   - receiver_whatsapp   : WhatsApp number (secondary routing hint)
///   - receiver_public_key : Ed25519 public key hex (discovered via server or QR)
///   - receiver_server_id  : Numeric server user ID (when known — fastest routing)
final class Migration029OutboxRoutingHeaders implements SchemaMigration {
  @override
  int get version => 29;

  @override
  Future<void> up(Database db) async {
    await db.execute(
        "ALTER TABLE outbox ADD COLUMN receiver_phone TEXT");
    await db.execute(
        "ALTER TABLE outbox ADD COLUMN receiver_whatsapp TEXT");
    await db.execute(
        "ALTER TABLE outbox ADD COLUMN receiver_public_key TEXT");
    await db.execute(
        "ALTER TABLE outbox ADD COLUMN receiver_server_id INTEGER");
  }
}
