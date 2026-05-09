import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/vouchers/confirm_voucher_use_case.dart';
import 'package:qayd/application/vouchers/dtos/confirm_voucher_input.dart';
import 'package:qayd/domain/repositories/fiscal_period_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/services/entry_generator.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/application/sync/sync_event_dispatcher.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/entry_side.dart';
import 'package:qayd/domain/value_objects/entry_id.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/error/failures.dart';

class MockVoucherRepository extends Mock implements VoucherRepository {}

class MockEntryGenerator extends Mock implements EntryGenerator {}

class MockIdGenerator extends Mock implements IdGenerator {}

class MockGovernanceWriteGuard extends Mock implements GovernanceWriteGuard {}

class MockSyncEventDispatcher extends Mock implements SyncEventDispatcher {}

class MockFiscalPeriodRepository extends Mock
    implements FiscalPeriodRepository {}

class FakeVoucher extends Fake implements Voucher {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeVoucher());
    registerFallbackValue(VoucherId('dummy'));
    registerFallbackValue(TransactionId('dummy'));
    registerFallbackValue(EntryId('dummy'));
  });

  late ConfirmVoucherUseCase useCase;
  late MockVoucherRepository mockVoucherRepo;
  late MockEntryGenerator mockEntryGen;
  late MockIdGenerator mockIdGen;
  late MockGovernanceWriteGuard mockWriteGuard;
  late MockSyncEventDispatcher mockSyncEventDispatcher;
  late MockFiscalPeriodRepository mockFiscalRepo;

  setUp(() {
    mockVoucherRepo = MockVoucherRepository();
    mockEntryGen = MockEntryGenerator();
    mockIdGen = MockIdGenerator();
    mockWriteGuard = MockGovernanceWriteGuard();
    mockSyncEventDispatcher = MockSyncEventDispatcher();
    mockFiscalRepo = MockFiscalPeriodRepository();
    when(() => mockFiscalRepo.listAllOrdered())
        .thenAnswer((_) async => const Success([]));

    useCase = ConfirmVoucherUseCase(
      mockVoucherRepo,
      mockEntryGen,
      mockIdGen,
      mockWriteGuard,
      mockFiscalRepo,
      syncEventDispatcher: mockSyncEventDispatcher,
    );
  });

  test('should return failure if not signed by anyone', () async {
    when(() => mockWriteGuard.assertWritesPermitted())
        .thenAnswer((_) async => const Success(null));

    final currency = CurrencyCode(
        code: 'USD', nameAr: 'USD', symbol: '\$', fractionalDigits: 2);
    final voucher = Voucher.restore(
      id: VoucherId('v-1'),
      type: VoucherType.receipt,
      date: DateTime.now(),
      amount: Money.positiveAmount(100, currency),
      currency: currency,
      counterpartyId: AccountId('cp-1'),
      affectedAccountId: AccountId('aff-1'),
      createdAt: DateTime.now(),
      state: VoucherState.draft,
      senderStatus: AgreementStatus.underRequest,
      receiverStatus: AgreementStatus.underRequest,
    );

    when(() => mockVoucherRepo.getById(any()))
        .thenAnswer((_) async => Success(voucher));

    final result = await useCase(ConfirmVoucherInput(voucherId: 'v-1'));

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(
        (result.failureOrNull as ValidationFailure).code, 'voucher_not_signed');
  });

  test('should confirm voucher successfully', () async {
    when(() => mockWriteGuard.assertWritesPermitted())
        .thenAnswer((_) async => const Success(null));

    final currency = CurrencyCode(
        code: 'USD', nameAr: 'USD', symbol: '\$', fractionalDigits: 2);
    var voucher = Voucher.draft(
      id: VoucherId('v-1'),
      type: VoucherType.receipt,
      date: DateTime.now(),
      amount: Money.positiveAmount(100, currency),
      currency: currency,
      counterpartyId: AccountId('cp-1'),
      affectedAccountId: AccountId('aff-1'),
      createdAt: DateTime.now(),
    );
    voucher = voucher.attachSignature(
        signatureHex: 'hex1',
        publicKeyHex: 'pub1',
        isSender: true,
        status: AgreementStatus.accepted,
        signerPhone: '1');
    voucher = voucher.attachSignature(
        signatureHex: 'hex2',
        publicKeyHex: 'pub2',
        isSender: false,
        status: AgreementStatus.accepted,
        signerPhone: '2');

    when(() => mockVoucherRepo.getById(any()))
        .thenAnswer((_) async => Success(voucher));

    when(() => mockIdGen.next()).thenReturn('id-mock');

    final debitEntry = LedgerEntry.create(
        id: EntryId('e1'),
        transactionId: TransactionId('t1'),
        accountId: AccountId('aff-1'),
        side: EntrySide.debit,
        amount: Money.positiveAmount(100, currency),
        currency: currency,
        voucherId: VoucherId('v-1'),
        date: DateTime.now(),
        createdAt: DateTime.now());
    final creditEntry = LedgerEntry.create(
        id: EntryId('e2'),
        transactionId: TransactionId('t1'),
        accountId: AccountId('cp-1'),
        side: EntrySide.credit,
        amount: Money.positiveAmount(100, currency),
        currency: currency,
        voucherId: VoucherId('v-1'),
        date: DateTime.now(),
        createdAt: DateTime.now());

    when(() => mockEntryGen.generateForConfirmedVoucher(
            voucher: any(named: 'voucher'),
            transactionId: any(named: 'transactionId'),
            debitEntryId: any(named: 'debitEntryId'),
            creditEntryId: any(named: 'creditEntryId'),
            ledgerCreatedAt: any(named: 'ledgerCreatedAt')))
        .thenReturn([debitEntry, creditEntry]);

    when(() => mockVoucherRepo.saveWithLedgerEntries(
            voucher: any(named: 'voucher'),
            ledgerEntries: any(named: 'ledgerEntries')))
        .thenAnswer((_) async => const Success(null));

    when(() => mockSyncEventDispatcher.dispatchVoucherAcceptance(any()))
        .thenAnswer((_) async {});

    final result = await useCase(ConfirmVoucherInput(voucherId: 'v-1'));

    expect(result.isSuccess, isTrue);
    verify(() => mockVoucherRepo.saveWithLedgerEntries(
        voucher: any(named: 'voucher'),
        ledgerEntries: any(named: 'ledgerEntries'))).called(1);
    verify(() => mockSyncEventDispatcher.dispatchVoucherAcceptance(any()))
        .called(1);
  });
}
