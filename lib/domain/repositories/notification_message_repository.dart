import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/notification_message.dart';

abstract class NotificationMessageRepository {
  Future<Result<void>> insert({
    required String id,
    required String bodyText,
    String? channel,
    required String counterpartyAccountId,
    required String createdAtIso,
    String? rawPayloadJson,
  });

  Future<Result<List<NotificationMessage>>> listUnprocessedForCounterparty({
    required String counterpartyAccountId,
    int limit,
  });

  Future<Result<List<NotificationMessage>>> listAllUnprocessed({int limit});

  Future<Result<void>> markProcessed(String id);
}
