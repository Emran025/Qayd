import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/notification_log_repository.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


final class SqliteNotificationLogRepository
    implements NotificationLogRepository {
  SqliteNotificationLogRepository(this._db);

  final Database _db;

  static const _table = 'notification_log';

  @override
  Future<Result<void>> insert(NotificationLogEntry entry) async {
    try {
      await _db.insert(_table, {
        'id': entry.id,
        'channel': entry.channel,
        'template_id': entry.templateId,
        'entity_type': entry.entityType,
        'entity_id': entry.entityId,
        'rendered_body_preview': entry.renderedBodyPreview,
        'status': entry.status,
        'created_at': entry.createdAtIso,
      });
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.theSendingAttemptCould),
      );
    }
  }
}
