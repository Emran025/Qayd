import 'dart:convert';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/sync/sync_event_dispatcher.dart';
import 'package:uuid/uuid.dart';

class CreateTripartiteRequestInput {
  const CreateTripartiteRequestInput({
    required this.mediatorAccountId,
    required this.destinationAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
  });

  /// The account ID of the mediator who will execute the transfer (B)
  final String mediatorAccountId;
  
  /// The account ID of the ultimate receiver (C)
  final String destinationAccountId;
  
  final int amountMinorUnits;
  final String currencyCode;
}

/// Allows Sender (A) to request Mediator (B) to initiate a tripartite transfer to Recipient (C).
class CreateTripartiteRequestUseCase {
  const CreateTripartiteRequestUseCase({
    required this.notificationRepo,
    required this.syncEventDispatcher,
  });

  final NotificationMessageRepository notificationRepo;
  final SyncEventDispatcher syncEventDispatcher;

  Future<Result<void>> call(CreateTripartiteRequestInput input) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();

      final payloadMap = {
        'type': 'tripartite_request',
        'destAccountId': input.destinationAccountId,
        'amountMinorUnits': input.amountMinorUnits,
        'currencyCode': input.currencyCode,
      };

      // 1. Local logging (Optional visibility for sender)
      await notificationRepo.insert(
        id: id,
        counterpartyAccountId: input.mediatorAccountId,
        bodyText: 'طلب إجراء حوالة ثنائية الأطراف',
        channel: 'outbound',
        createdAtIso: now.toIso8601String(),
        rawPayloadJson: jsonEncode(payloadMap),
      );

      // 2. Protocol §5: E2EE Dispatch to Mediator (B)
      // This ensures the server is "blind" as the payload is encrypted for B's public key.
      final dispatchRes = await syncEventDispatcher.dispatchGenericEvent(
        counterpartyAccountId: input.mediatorAccountId,
        eventType: 'tripartite_request',
        payload: payloadMap,
      );

      return dispatchRes;
    } catch (e) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}

