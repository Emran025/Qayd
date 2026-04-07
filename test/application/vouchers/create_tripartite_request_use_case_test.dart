import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/vouchers/create_tripartite_request_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/application/sync/sync_event_dispatcher.dart';
import 'package:qayd/core/error/failures.dart';

class MockNotificationMessageRepository extends Mock implements NotificationMessageRepository {}
class MockSyncEventDispatcher extends Mock implements SyncEventDispatcher {}

void main() {
  late CreateTripartiteRequestUseCase useCase;
  late MockNotificationMessageRepository mockNotificationRepo;
  late MockSyncEventDispatcher mockSyncDispatcher;

  setUp(() {
    mockNotificationRepo = MockNotificationMessageRepository();
    mockSyncDispatcher = MockSyncEventDispatcher();
    useCase = CreateTripartiteRequestUseCase(
      notificationRepo: mockNotificationRepo,
      syncEventDispatcher: mockSyncDispatcher,
    );
  });

  const input = CreateTripartiteRequestInput(
    mediatorAccountId: 'mediator-123',
    destinationAccountId: 'dest-456',
    amountMinorUnits: 1000,
    currencyCode: 'SAR',
  );

  group('CreateTripartiteRequestUseCase', () {
    test('should succeed when both repo and dispatcher calls are successful', () async {
      // Arrange
      when(() => mockNotificationRepo.insert(
            id: any(named: 'id'),
            counterpartyAccountId: any(named: 'counterpartyAccountId'),
            bodyText: any(named: 'bodyText'),
            channel: any(named: 'channel'),
            createdAtIso: any(named: 'createdAtIso'),
            rawPayloadJson: any(named: 'rawPayloadJson'),
          )).thenAnswer((_) async => const Success(null));

      when(() => mockSyncDispatcher.dispatchGenericEvent(
            counterpartyAccountId: any(named: 'counterpartyAccountId'),
            eventType: any(named: 'eventType'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase.call(input);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(() => mockNotificationRepo.insert(
            id: any(named: 'id'),
            counterpartyAccountId: input.mediatorAccountId,
            channel: 'outbound',
            rawPayloadJson: any(named: 'rawPayloadJson'),
            bodyText: any(named: 'bodyText'),
            createdAtIso: any(named: 'createdAtIso'),
          )).called(1);
          
      verify(() => mockSyncDispatcher.dispatchGenericEvent(
            counterpartyAccountId: input.mediatorAccountId,
            eventType: 'tripartite_request',
            payload: any(named: 'payload'),
          )).called(1);
    });

    test('should return failure when syncEventDispatcher fails', () async {
      // Arrange
      when(() => mockNotificationRepo.insert(
            id: any(named: 'id'),
            counterpartyAccountId: any(named: 'counterpartyAccountId'),
            bodyText: any(named: 'bodyText'),
            channel: any(named: 'channel'),
            createdAtIso: any(named: 'createdAtIso'),
            rawPayloadJson: any(named: 'rawPayloadJson'),
          )).thenAnswer((_) async => const Success(null));

      when(() => mockSyncDispatcher.dispatchGenericEvent(
            counterpartyAccountId: any(named: 'counterpartyAccountId'),
            eventType: any(named: 'eventType'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => const FailureResult(ValidationFailure(messageAr: 'خطأ في التشفير')));

      // Act
      final result = await useCase.call(input);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.messageAr, 'خطأ في التشفير');
    });

    test('should return failure when unexpected exception occurs', () async {
      // Arrange
      when(() => mockNotificationRepo.insert(
            id: any(named: 'id'),
            counterpartyAccountId: any(named: 'counterpartyAccountId'),
            bodyText: any(named: 'bodyText'),
            channel: any(named: 'channel'),
            createdAtIso: any(named: 'createdAtIso'),
            rawPayloadJson: any(named: 'rawPayloadJson'),
          )).thenThrow(Exception('DB Error'));

      // Act
      final result = await useCase.call(input);

      // Assert
      expect(result.isFailure, isTrue);
    });
  });
}
