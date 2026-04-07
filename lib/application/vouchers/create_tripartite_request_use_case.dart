import 'dart:convert';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/application/failure_mapping.dart';
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
  const CreateTripartiteRequestUseCase(this.notificationRepo);

  final NotificationMessageRepository notificationRepo;

  Future<Result<void>> call(CreateTripartiteRequestInput input) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();

      // Encode the specific request data in the payload to drive UI deep linking
      final payloadJson = jsonEncode({
        'type': 'tripartite_request',
        'destAccountId': input.destinationAccountId,
        'amountMinorUnits': input.amountMinorUnits,
        'currencyCode': input.currencyCode,
      });

      final r = await notificationRepo.insert(
        id: id,
        counterpartyAccountId: input.mediatorAccountId,
        bodyText: 'طلب إجراء حوالة ثنائية الأطراف',
        channel: 'in_app', // Local simulation indicator
        createdAtIso: now.toIso8601String(),
        rawPayloadJson: payloadJson,
      );

      if (r.isFailure) return FailureResult(r.failureOrNull!);

      return const Success(null);
    } catch (e) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
