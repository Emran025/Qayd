import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


/// Data model for an outbox entry.
class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.eventType,
    this.voucherId,
    required this.counterpartyAccountId,
    required this.encryptedPayload,
    required this.state,
    this.transport,
    required this.retryCount,
    required this.createdAt,
    this.deliveredAt,
  });

  final String id;
  final String eventType;
  final String? voucherId;
  final String counterpartyAccountId;
  final String encryptedPayload;
  final String state; // 'pending', 'delivered', 'failed'
  final String? transport; // 'server', 'p2p'
  final int retryCount;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'event_type': eventType,
        'voucher_id': voucherId,
        'counterparty_account_id': counterpartyAccountId,
        'encrypted_payload': encryptedPayload,
        'state': state,
        'transport': transport,
        'retry_count': retryCount,
        'created_at': createdAt.toIso8601String(),
        'delivered_at': deliveredAt?.toIso8601String(),
      };

  factory OutboxEntry.fromMap(Map<String, Object?> map) {
    return OutboxEntry(
      id: map['id']! as String,
      eventType: map['event_type']! as String,
      voucherId: map['voucher_id'] as String?,
      counterpartyAccountId: map['counterparty_account_id']! as String,
      encryptedPayload: map['encrypted_payload']! as String,
      state: map['state']! as String,
      transport: map['transport'] as String?,
      retryCount: (map['retry_count'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at']! as String),
      deliveredAt: map['delivered_at'] != null
          ? DateTime.parse(map['delivered_at']! as String)
          : null,
    );
  }
}

/// Local Outbox DAO — persists mutations until acknowledged by server or P2P peer.
///
/// Protocol §5.A: Every voucher creation, state transition, signature attachment,
/// or metadata mutation is appended here before any network operation is attempted.
class OutboxDao {
  const OutboxDao(this._db);

  final Database _db;
  static const _table = 'outbox';

  /// Enqueue a new mutation into the outbox.
  Future<Result<void>> enqueue(OutboxEntry entry) async {
    try {
      await _db.insert(
        _table,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.theEntryCouldNot),
      );
    }
  }

  /// Fetch all pending outbox entries (for flush on reconnection).
  Future<Result<List<OutboxEntry>>> listPending() async {
    try {
      final rows = await _db.query(
        _table,
        where: "state = ?",
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
      );
      return Success(rows.map(OutboxEntry.fromMap).toList());
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.theOutboxCouldNot),
      );
    }
  }

  /// Fetch pending entries for a specific counterparty (for P2P context-scoped sync).
  Future<Result<List<OutboxEntry>>> listPendingForCounterparty(
    String counterpartyAccountId,
  ) async {
    try {
      final rows = await _db.query(
        _table,
        where: "state = ? AND counterparty_account_id = ?",
        whereArgs: ['pending', counterpartyAccountId],
        orderBy: 'created_at ASC',
      );
      return Success(rows.map(OutboxEntry.fromMap).toList());
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.thePartysOutboxCould),
      );
    }
  }

  /// Mark entries as delivered after receiving acknowledgment.
  Future<Result<void>> markDelivered(
    List<String> ids, {
    String transport = 'server',
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      for (final id in ids) {
        await _db.update(
          _table,
          {
            'state': 'delivered',
            'transport': transport,
            'delivered_at': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.unableToUpdateDelivery),
      );
    }
  }

  /// Increment retry count for failed delivery attempts.
  Future<void> incrementRetry(String id) async {
    await _db.rawUpdate(
      'UPDATE $_table SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  /// Purge delivered entries older than [days] from the outbox.
  Future<void> purgeDelivered({int days = 30}) async {
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    await _db.delete(
      _table,
      where: "state = 'delivered' AND delivered_at < ?",
      whereArgs: [cutoff],
    );
  }
}
