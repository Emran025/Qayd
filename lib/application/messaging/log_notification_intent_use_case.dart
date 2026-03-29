import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/repositories/notification_log_repository.dart'
    show NotificationLogEntry, NotificationLogRepository;
import 'package:qayd/domain/repositories/notification_message_repository.dart';

class LogNotificationIntentUseCase {
  LogNotificationIntentUseCase(
    this._repo,
    this._notificationMessages,
    this._ids,
  );

  final NotificationLogRepository _repo;
  final NotificationMessageRepository _notificationMessages;
  final IdGenerator _ids;

  /// Records that the user launched an external messaging intent (offline audit).
  /// When [suggestionCounterpartyAccountId] is set, also stores the body for voucher suggestions.
  Future<Result<void>> call({
    required String channel,
    String? templateId,
    required String entityType,
    required String entityId,
    required String renderedBody,
    String status = 'intent_launched',
    String? suggestionCounterpartyAccountId,
  }) async {
    final preview = renderedBody.length > 500
        ? renderedBody.substring(0, 500)
        : renderedBody;
    final logR = await _repo.insert(
      NotificationLogEntry(
        id: _ids.next(),
        channel: channel,
        templateId: templateId,
        entityType: entityType,
        entityId: entityId,
        renderedBodyPreview: preview,
        status: status,
        createdAtIso: DateTime.now().toIso8601String(),
      ),
    );
    if (logR.isFailure) {
      return logR;
    }
    final cp = suggestionCounterpartyAccountId?.trim();
    if (cp != null &&
        cp.isNotEmpty &&
        renderedBody.trim().isNotEmpty) {
      return _notificationMessages.insert(
        id: _ids.next(),
        bodyText: renderedBody,
        channel: channel,
        counterpartyAccountId: cp,
        createdAtIso: DateTime.now().toIso8601String(),
      );
    }
    return const Success(null);
  }
}
