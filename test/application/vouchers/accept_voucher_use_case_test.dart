import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/vouchers/accept_voucher_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/sync_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/services/receipt_signing_service.dart';
import 'package:qayd/domain/services/e2ee_encryption_service.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/domain/entities/party_details.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/digital_signature.dart';
import 'package:qayd/domain/value_objects/signable_receipt.dart';
import 'package:qayd/domain/entities/sync_node.dart';
import 'dart:typed_data';

class MockVoucherRepository extends Mock implements VoucherRepository {}
class FakeSyncNode extends Fake implements SyncNode {}
class MockAccountRepository extends Mock implements AccountRepository {}
class MockSyncRepository extends Mock implements SyncRepository {}
class MockReceiptSigningService extends Mock implements ReceiptSigningService {}
class MockE2EEEncryptionService extends Mock implements E2EEEncryptionService {}
class FakeVoucher extends Fake implements Voucher {}
class MockLicenseVault extends Mock implements LicenseVault {}

void main() {
  late AcceptVoucherUseCase useCase;
  late MockVoucherRepository mockVoucherRepo;
  late MockAccountRepository mockAccountRepo;
  late MockSyncRepository mockSyncRepo;
  late MockReceiptSigningService mockSigningService;
  late MockE2EEEncryptionService mockE2EEService;
  late MockLicenseVault mockLicenseVault;

  setUp(() {
    mockVoucherRepo = MockVoucherRepository();
    mockAccountRepo = MockAccountRepository();
    mockSyncRepo = MockSyncRepository();
    mockSigningService = MockReceiptSigningService();
    mockE2EEService = MockE2EEEncryptionService();
    mockLicenseVault = MockLicenseVault();

    useCase = AcceptVoucherUseCase(
      voucherRepository: mockVoucherRepo,
      accountRepository: mockAccountRepo,
      syncRepository: mockSyncRepo,
      signingService: mockSigningService,
      e2eeEncryptionService: mockE2EEService,
      getCurrentUserKeyPair: () async => throw Exception('Not implemented for testing failure cases'),
      licenseVault: mockLicenseVault,
    );
  });

  setUpAll(() {
    registerFallbackValue(FakeVoucher());
    registerFallbackValue(FakeSyncNode());
    registerFallbackValue(VoucherId('dummy'));
    registerFallbackValue(AccountId('dummy'));
    registerFallbackValue(SignableReceipt(amountMinor: 100, currencyCode: 'USD', senderPhone: '1', receiverPhone: '2', dateIso: '1', receiptUuid: '1'));
    registerFallbackValue(CryptoKeyPair(publicKey: Uint8List(32), privateKey: Uint8List(32)));
  });

  test('should return failure if voucher does not exist', () async {
    when(() => mockVoucherRepo.getById(any()))
        .thenAnswer((_) async => FailureResult(ValidationFailure(messageAr: 'السند غير موجود.')));

    final result = await useCase('v-123');

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect((result.failureOrNull as ValidationFailure).messageAr, 'السند غير موجود.');
  });

  test('should handle exception gracefully', () async {
    when(() => mockVoucherRepo.getById(any()))
        .thenThrow(Exception('Unexpected failure'));

    final result = await useCase('v-123');

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });

  test('should return failure if voucher is already accepted', () async {
    final currency = CurrencyCode(code: 'USD', nameAr: 'دولار أمريكي', symbol: r'$', fractionalDigits: 2, isActive: true);
    final voucher = Voucher.draft(
      id: VoucherId('v-123'),
      type: VoucherType.receipt,
      date: DateTime.now(),
      amount: Money.positiveAmount(100, currency),
      currency: currency,
      counterpartyId: AccountId('cp-1'),
      affectedAccountId: AccountId('aff-1'),
      createdAt: DateTime.now(),
    );
    // simulate accepted status
    final acceptedVoucher = voucher.attachSignature(
        signatureHex: 'hex',
        publicKeyHex: 'pubhex',
        isSender: false,
        status: AgreementStatus.accepted,
        signerPhone: '123'
    );
    
    when(() => mockVoucherRepo.getById(any()))
        .thenAnswer((_) async => Success(acceptedVoucher));

    final result = await useCase('v-123');

    expect(result.isFailure, isTrue);
    expect((result.failureOrNull as ValidationFailure).messageAr, 'السند مقبول مسبقاً.');
  });

  test('should accept voucher successfully', () async {
    final currency = CurrencyCode(code: 'USD', nameAr: 'دولار أمريكي', symbol: r'$', fractionalDigits: 2, isActive: true);
    final voucher = Voucher.draft(
      id: VoucherId('v-123'),
      type: VoucherType.receipt,
      date: DateTime.now(),
      amount: Money.positiveAmount(100, currency),
      currency: currency,
      counterpartyId: AccountId('cp-1'),
      affectedAccountId: AccountId('aff-1'),
      createdAt: DateTime.now(),
    );
    
    when(() => mockVoucherRepo.getById(any()))
        .thenAnswer((_) async => Success(voucher));
    
    when(() => mockLicenseVault.readLicenseData())
        .thenAnswer((_) async => {'phone': '12345', 'id': 1});

    when(() => mockAccountRepo.getPartyDetails(any()))
        .thenAnswer((_) async => Success(PartyDetails(accountId: AccountId('cp-1'), currentPublicKeyHex: 'cp-pub', publicKeyHistoryHex: [], serverAccountId: 2)));

    when(() => mockSigningService.signReceipt(any(), any()))
        .thenReturn(DigitalSignature(signatureBytes: Uint8List(64), signerPublicKey: Uint8List(32), payloadHash: Uint8List(32)));

    when(() => mockVoucherRepo.save(any()))
        .thenAnswer((_) async => const Success(null));

    when(() => mockE2EEService.encryptPayload(rawPayload: any(named: 'rawPayload'), senderKeyPair: any(named: 'senderKeyPair'), receiverPublicKeyHex: any(named: 'receiverPublicKeyHex')))
        .thenAnswer((_) async => 'encrypted');

    when(() => mockSyncRepo.pushNode(any()))
        .thenAnswer((_) async => const Success(null));

    // For this test we need to pass a key pair, so we override the useCase specifically for it
    useCase = AcceptVoucherUseCase(
      voucherRepository: mockVoucherRepo,
      accountRepository: mockAccountRepo,
      syncRepository: mockSyncRepo,
      signingService: mockSigningService,
      e2eeEncryptionService: mockE2EEService,
      getCurrentUserKeyPair: () async => CryptoKeyPair(publicKey: Uint8List(32), privateKey: Uint8List(32)),
      licenseVault: mockLicenseVault,
    );

    final result = await useCase('v-123');

    expect(result.isSuccess, isTrue);
    verify(() => mockVoucherRepo.save(any())).called(1);
  });
}
