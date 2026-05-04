import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// Per-counterparty sync watermark — tracks the last successful sync point
/// and the counterparty's read position for each bilateral relationship.
///
/// Protocol §5.B: Determines the `since` parameter for delta sync — only
/// mutations after `last_synced_at` for that specific counterparty are transmitted.
class SyncWatermark {
  const SyncWatermark({
    required this.counterpartyAccountId,
    required this.lastSyncedAt,
    this.lastOpenedVoucherId,
    required this.transport,
  });

  final String counterpartyAccountId;
  final DateTime lastSyncedAt;
  final String? lastOpenedVoucherId;
  final String transport; // 'server' or 'p2p'

  Map<String, Object?> toMap() => {
        'counterparty_account_id': counterpartyAccountId,
        'last_synced_at': lastSyncedAt.toIso8601String(),
        'last_opened_voucher_id': lastOpenedVoucherId,
        'transport': transport,
      };

  factory SyncWatermark.fromMap(Map<String, Object?> map) {
    return SyncWatermark(
      counterpartyAccountId: map['counterparty_account_id']! as String,
      lastSyncedAt: DateTime.parse(map['last_synced_at']! as String),
      lastOpenedVoucherId: map['last_opened_voucher_id'] as String?,
      transport: (map['transport'] as String?) ?? 'server',
    );
  }
}

/// DAO for the per-counterparty sync watermark table.
///
/// Enables delta sync scope determination and "read receipts" functionality.
class SyncWatermarkDao {
  const SyncWatermarkDao(this._db);

  final Database _db;
  static const _table = 'sync_watermarks';

  /// Get the watermark for a specific counterparty.
  Future<Result<SyncWatermark?>> getForCounterparty(
    String counterpartyAccountId,
  ) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'counterparty_account_id = ?',
        whereArgs: [counterpartyAccountId],
        limit: 1,
      );
      if (rows.isEmpty) return const Success(null);
      return Success(SyncWatermark.fromMap(rows.first));
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(
          messageAr: AppStrings.theSyncTagCould,
        ),
      );
    }
  }

  /// Upsert the watermark for a specific counterparty after successful sync.
  Future<Result<void>> upsert(SyncWatermark watermark) async {
    try {
      await _db.insert(
        _table,
        watermark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(
          messageAr: AppStrings.unableToUpdateSync,
        ),
      );
    }
  }

  /// Update the last opened voucher (read receipt) for a counterparty.
  Future<Result<void>> updateLastOpened({
    required String counterpartyAccountId,
    required String lastOpenedVoucherId,
  }) async {
    try {
      await _db.update(
        _table,
        {'last_opened_voucher_id': lastOpenedVoucherId},
        where: 'counterparty_account_id = ?',
        whereArgs: [counterpartyAccountId],
      );
      return const Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(
          messageAr: AppStrings.theLastOpenDocument,
        ),
      );
    }
  }

  /// Get all watermarks (used during full sync status reporting).
  Future<Result<List<SyncWatermark>>> listAll() async {
    try {
      final rows = await _db.query(_table, orderBy: 'last_synced_at DESC');
      return Success(rows.map(SyncWatermark.fromMap).toList());
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(
          messageAr: AppStrings.theSynchronizationTableCould,
        ),
      );
    }
  }
}
