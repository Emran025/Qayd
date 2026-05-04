import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/notification_message.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


final class SqliteNotificationMessageRepository
    implements NotificationMessageRepository {
  SqliteNotificationMessageRepository(this._db);

  final Database _db;

  static const _table = 'notification_messages';

  @override
  Future<Result<void>> insert({
    required String id,
    required String bodyText,
    String? channel,
    required String counterpartyAccountId,
    required String createdAtIso,
    String? rawPayloadJson,
  }) async {
    try {
      await _db.insert(_table, {
        'id': id,
        'body_text': bodyText,
        'channel': channel,
        'context_kind': 'counterparty',
        'context_ref': counterpartyAccountId,
        'created_at': createdAtIso,
        'raw_payload_json': rawPayloadJson,
        'counterparty_account_id': counterpartyAccountId,
        'processed': 0,
      });
      return  Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToSaveNotification),
      );
    }
  }

  @override
  Future<Result<List<NotificationMessage>>> listUnprocessedForCounterparty({
    required String counterpartyAccountId,
    int limit = 50,
  }) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'counterparty_account_id = ? AND processed = 0',
        whereArgs: [counterpartyAccountId],
        orderBy: 'created_at DESC',
        limit: limit,
      );
      final out = <NotificationMessage>[];
      for (final r in rows) {
        final cp = r['counterparty_account_id'] as String?;
        if (cp == null || cp.isEmpty) continue;
        final created = r['created_at'] as String?;
        if (created == null) continue;
        out.add(
          NotificationMessage(
            id: r['id'] as String,
            bodyText: r['body_text'] as String,
            channel: r['channel'] as String?,
            counterpartyAccountId: cp,
            createdAt: DateTime.parse(created),
            processed: (r['processed'] as int? ?? 0) != 0,
            rawPayloadJson: r['raw_payload_json'] as String?,
          ),
        );
      }
      return Success(out);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToLoadNotification),
      );
    }
  }

  @override
  Future<Result<List<NotificationMessage>>> listAllUnprocessed({
    int limit = 100,
  }) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'processed = 0',
        orderBy: 'created_at DESC',
        limit: limit,
      );
      final out = <NotificationMessage>[];
      for (final r in rows) {
        final cp = r['counterparty_account_id'] as String? ?? '';
        final created = r['created_at'] as String?;
        if (created == null) continue;
        out.add(
          NotificationMessage(
            id: r['id'] as String,
            bodyText: r['body_text'] as String,
            channel: r['channel'] as String?,
            counterpartyAccountId: cp,
            createdAt: DateTime.parse(created),
            processed: (r['processed'] as int? ?? 0) != 0,
            rawPayloadJson: r['raw_payload_json'] as String?,
          ),
        );
      }
      return Success(out);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToLoadInbox),
      );
    }
  }

  @override
  Future<Result<void>> markProcessed(String id) async {
    try {
      final n = await _db.update(
        _table,
        {'processed': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (n == 0) {
        return  FailureResult(
          DatabaseFailure(messageAr: AppStrings.notificationRecordNotFound),
        );
      }
      return  Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToUpdateNotification),
      );
    }
  }
}
