import 'dart:typed_data';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/application/sync/sync_payload_processor.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/sync_node.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/services/e2ee_encryption_service.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/repositories/attachment_repository.dart';
import 'package:qayd/domain/repositories/collateral_repository.dart';
import 'package:qayd/domain/services/receipt_signing_service.dart';
import 'package:qayd/data/encryption/voucher_key_service.dart';
import 'package:qayd/domain/services/notification_filter_service.dart';
import 'package:qayd/domain/entities/party_details.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';

class MockIdentityRepository extends Mock implements IdentityRepository {}

class MockVoucherRepository extends Mock implements VoucherRepository {}

class MockLedgerRepository extends Mock implements LedgerRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockCurrencyRepository extends Mock implements CurrencyRepository {}

class MockNotificationMessageRepository extends Mock
    implements NotificationMessageRepository {}

class MockE2EEEncryptionService extends Mock implements E2EEEncryptionService {}

class MockReceiptSigningService extends Mock implements ReceiptSigningService {}

class MockAttachmentRepository extends Mock implements AttachmentRepository {}

class MockCollateralRepository extends Mock implements CollateralRepository {}

class MockVoucherKeyService extends Mock implements VoucherKeyService {}

class MockNotificationFilterService extends Mock
    implements NotificationFilterService {}

void main() {
  late SyncPayloadProcessor processor;
  late MockIdentityRepository mockIdentityRepo;
  late MockAccountRepository mockAccountRepo;
  late MockNotificationMessageRepository mockNotificationRepo;
  late MockNotificationFilterService mockFilterRepo;
  late MockE2EEEncryptionService mockE2ee;

  setUp(() {
    mockIdentityRepo = MockIdentityRepository();
    mockAccountRepo = MockAccountRepository();
    mockNotificationRepo = MockNotificationMessageRepository();
    mockFilterRepo = MockNotificationFilterService();
    mockE2ee = MockE2EEEncryptionService();

    when(() => mockFilterRepo.isPeerActivityEnabled).thenReturn(true);
    when(() => mockFilterRepo.isSelfActivityEnabled).thenReturn(true);

    processor = SyncPayloadProcessor(
      identityRepository: mockIdentityRepo,
      voucherRepository: MockVoucherRepository(),
      ledgerRepository: MockLedgerRepository(),
      accountRepository: mockAccountRepo,
      currencyRepository: MockCurrencyRepository(),
      notificationMessageRepository: mockNotificationRepo,
      notificationFilterService: mockFilterRepo,
      e2eeService: mockE2ee,
      signingService: MockReceiptSigningService(),
      getCurrentUserKeyPair: () async => CryptoKeyPair.fromHex(
        publicKeyHex:
            '0000000000000000000000000000000000000000000000000000000000000000',
        privateKeyHex:
            '0000000000000000000000000000000000000000000000000000000000000000',
      ),
      attachmentRepository: MockAttachmentRepository(),
      collateralRepository: MockCollateralRepository(),
      voucherKeyService: MockVoucherKeyService(),
    );

    registerFallbackValue(
        CryptoKeyPair(publicKey: Uint8List(32), privateKey: Uint8List(32)));
  });

  group('SyncPayloadProcessor - TripartiteRequest', () {
    test('should process inbound tripartite request and save notification',
        () async {
      // Arrange
      final node = SyncNode(
        id: 'node-123',
        senderId: 101, // Sender A
        receiverId: 202, // Me (B)
        eventType: SyncEventType.tripartiteRequest,
        encryptedPayload: 'secret-payload',
        syncState: 'pending',
        clientTimestamp: DateTime.now(),
      );

      final partyDetails = PartyDetails(
        accountId: AccountId('101'),
        phoneNumber: '0500000000',
        currentPublicKeyHex: 'sender-pub',
      );

      final senderLookup = PublicKeyLookupResult(
        phone: '0500000000',
        publicKeyHex: 'sender-pub',
        keyGeneration: 1,
        name: 'Sender A',
      );

      final senderAccount = Account.createRoot(
        id: AccountId('101'),
        name: 'Sender A',
        classification: AccountClassification.personalExpenses,
        createdAt: DateTime.now(),
      );

      when(() => mockAccountRepo.getPartyDetails(AccountId('101')))
          .thenAnswer((_) async => Success(partyDetails));
      when(() => mockIdentityRepo.lookupByPhone(phone: any(named: 'phone')))
          .thenAnswer((_) async => senderLookup);
      when(() => mockE2ee.decryptPayload(
            encryptedPayload: any(named: 'encryptedPayload'),
            receiverKeyPair: any(named: 'receiverKeyPair'),
            senderPublicKeyHex: any(named: 'senderPublicKeyHex'),
          )).thenAnswer((_) async => {
            'type': 'tripartite_request',
            'amountMinorUnits': 1000,
            'currencyCode': 'SAR',
          });

      when(() => mockAccountRepo.getById(AccountId('101')))
          .thenAnswer((_) async => Success(senderAccount));
      when(() => mockNotificationRepo.insert(
            id: any(named: 'id'),
            counterpartyAccountId: any(named: 'counterpartyAccountId'),
            bodyText: any(named: 'bodyText'),
            channel: any(named: 'channel'),
            createdAtIso: any(named: 'createdAtIso'),
            rawPayloadJson: any(named: 'rawPayloadJson'),
          )).thenAnswer((_) async => const Success(null));

      // Act
      await processor.processIncomingNodes([node]);

      // Assert
      verify(() => mockNotificationRepo.insert(
            id: any(named: 'id'),
            counterpartyAccountId: '101',
            bodyText: any(named: 'bodyText', that: contains('Sender A')),
            channel: 'tripartite_event',
            createdAtIso: any(named: 'createdAtIso'),
            rawPayloadJson: any(named: 'rawPayloadJson'),
          )).called(1);
    });

    test('should NOT save notification when peer activity is disabled',
        () async {
      // Arrange
      when(() => mockFilterRepo.isPeerActivityEnabled).thenReturn(false);

      final node = SyncNode(
        id: 'node-123',
        senderId: 101,
        receiverId: 202,
        eventType: SyncEventType.tripartiteRequest,
        encryptedPayload: 'secret-payload',
        syncState: 'pending',
        clientTimestamp: DateTime.now(),
      );

      final partyDetails = PartyDetails(
        accountId: AccountId('101'),
        phoneNumber: '0500000000',
        currentPublicKeyHex: 'sender-pub',
      );

      final senderLookup = PublicKeyLookupResult(
        phone: '0500000000',
        publicKeyHex: 'sender-pub',
        keyGeneration: 1,
        name: 'Sender A',
      );

      when(() => mockAccountRepo.getPartyDetails(AccountId('101')))
          .thenAnswer((_) async => Success(partyDetails));
      when(() => mockIdentityRepo.lookupByPhone(phone: any(named: 'phone')))
          .thenAnswer((_) async => senderLookup);
      when(() => mockE2ee.decryptPayload(
            encryptedPayload: any(named: 'encryptedPayload'),
            receiverKeyPair: any(named: 'receiverKeyPair'),
            senderPublicKeyHex: any(named: 'senderPublicKeyHex'),
          )).thenAnswer((_) async => {
            'type': 'tripartite_request',
            'amountMinorUnits': 1000,
            'currencyCode': 'SAR',
          });

      when(() => mockAccountRepo.getById(AccountId('101'))).thenAnswer(
          (_) async => Success(Account.createRoot(
              id: AccountId('101'),
              name: 'Sender A',
              classification: AccountClassification.personalExpenses,
              createdAt: DateTime.now())));

      // Act
      await processor.processIncomingNodes([node]);

      // Assert
      verifyNever(() => mockNotificationRepo.insert(
            id: any(named: 'id'),
            counterpartyAccountId: any(named: 'counterpartyAccountId'),
            bodyText: any(named: 'bodyText'),
            channel: any(named: 'channel'),
            createdAtIso: any(named: 'createdAtIso'),
            rawPayloadJson: any(named: 'rawPayloadJson'),
          ));
    });
  });
}
