import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';

final class MarkNotificationMessageProcessedUseCase {
  MarkNotificationMessageProcessedUseCase(this._repo);

  final NotificationMessageRepository _repo;

  Future<Result<void>> call(String messageId) => _repo.markProcessed(messageId);
}
