import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/accounts/get_account_statement_use_case.dart';
import 'package:qayd/application/accounts/dtos/get_account_statement_input.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/entry_side.dart';
import 'package:qayd/domain/value_objects/entry_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockLedgerRepository extends Mock implements LedgerRepository {}

class MockVoucherRepository extends Mock implements VoucherRepository {}

void main() {
  late GetAccountStatementUseCase useCase;
  late MockAccountRepository mockAccountRepo;
  late MockLedgerRepository mockLedgerRepo;
  late MockVoucherRepository mockVoucherRepo;

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockLedgerRepo = MockLedgerRepository();
    mockVoucherRepo = MockVoucherRepository();

    useCase = GetAccountStatementUseCase(
      mockAccountRepo,
      mockLedgerRepo,
      mockVoucherRepo,
    );
  });

  test('should return failure if date range is invalid', () async {
    final input = GetAccountStatementInput(
      accountId: 'acc-1',
      fromDate: DateTime(2023, 1, 2),
      toDate: DateTime(2023, 1, 1),
    );

    final result = await useCase(input);

    expect(result.isFailure, isTrue);
    expect((result.failureOrNull as ValidationFailure).code,
        'statement_date_range');
  });

  test('should generate account statement successfully', () async {
    final input = GetAccountStatementInput(accountId: 'acc-1');
    final account = Account.createRoot(
      id: AccountId('acc-1'),
      name: 'Test Account',
      classification: AccountClassification.liquidAssets, // debit nature
      createdAt: DateTime.now(),
    );
    final currency = CurrencyCode(
        code: 'USD',
        nameAr: 'دولار',
        symbol: r'$',
        fractionalDigits: 2,
        isActive: true);

    final entry1 = LedgerEntry.create(
      id: EntryId('e1'),
      transactionId: TransactionId('t1'),
      voucherId: VoucherId('v1'),
      accountId: AccountId('acc-1'),
      amount: Money.positiveAmount(100, currency),
      currency: currency,
      side: EntrySide.debit, // +100
      date: DateTime(2023, 1, 1),
      createdAt: DateTime(2023, 1, 1),
    );

    final entry2 = LedgerEntry.create(
      id: EntryId('e2'),
      transactionId: TransactionId('t1'),
      voucherId: VoucherId('v2'),
      accountId: AccountId('acc-1'),
      amount: Money.positiveAmount(50, currency),
      currency: currency,
      side: EntrySide.credit, // -50
      date: DateTime(2023, 1, 2),
      createdAt: DateTime(2023, 1, 2),
    );

    final v1 = Voucher.draft(
        id: VoucherId('v1'),
        type: VoucherType.receipt,
        date: DateTime(2023, 1, 1),
        amount: Money.positiveAmount(100, currency),
        currency: currency,
        counterpartyId: AccountId('cp1'),
        affectedAccountId: AccountId('acc-1'),
        createdAt: DateTime.now(),
        description: 'v1 desc');
    final v2 = Voucher.draft(
        id: VoucherId('v2'),
        type: VoucherType.payment,
        date: DateTime(2023, 1, 2),
        amount: Money.positiveAmount(50, currency),
        currency: currency,
        counterpartyId: AccountId('cp1'),
        affectedAccountId: AccountId('acc-1'),
        createdAt: DateTime.now(),
        description: 'v2 desc');

    when(() => mockAccountRepo.getById(AccountId('acc-1')))
        .thenAnswer((_) async => Success(account));
    when(() => mockLedgerRepo.getEntriesForAccount(AccountId('acc-1')))
        .thenAnswer((_) async => Success([entry2, entry1])); // unordered
    when(() => mockVoucherRepo.getById(VoucherId('v1')))
        .thenAnswer((_) async => Success(v1));
    when(() => mockVoucherRepo.getById(VoucherId('v2')))
        .thenAnswer((_) async => Success(v2));

    final result = await useCase(input);

    expect(result.isSuccess, isTrue);
    final out = result.valueOrNull!;
    expect(out.accountId, 'acc-1');
    expect(out.lines.length, 2);
    // Should be sorted by date
    expect(out.lines[0].description, 'v1 desc');
    expect(out.lines[0].balanceMinorUnits, 100);
    expect(out.lines[1].description, 'v2 desc');
    expect(out.lines[1].balanceMinorUnits, 50); // 100 - 50
  });

  test('should handle exception gracefully', () async {
    final input = GetAccountStatementInput(accountId: 'acc-1');
    when(() => mockAccountRepo.getById(AccountId('acc-1')))
        .thenThrow(Exception('Unexpected failure'));

    final result = await useCase(input);

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });
}
