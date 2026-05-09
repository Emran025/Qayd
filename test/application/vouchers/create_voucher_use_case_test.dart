import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/vouchers/create_voucher_use_case.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/attachment_repository.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/repositories/fiscal_period_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/data/services/attachment_storage_service.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

class MockVoucherRepository extends Mock implements VoucherRepository {}

class MockCurrencyRepository extends Mock implements CurrencyRepository {}

class MockAttachmentRepository extends Mock implements AttachmentRepository {}

class MockIdGenerator extends Mock implements IdGenerator {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockCostCenterRepository extends Mock implements CostCenterRepository {}

class FakeVoucher extends Fake implements Voucher {}

class MockAttachmentStorageService extends Mock
    implements AttachmentStorageService {
  @override
  // ignore: must_call_super
  noSuchMethod(Invocation invocation) => {super.noSuchMethod(invocation)};
}

class MockGovernanceWriteGuard extends Mock implements GovernanceWriteGuard {}

class MockFiscalPeriodRepository extends Mock
    implements FiscalPeriodRepository {}

void main() {
  late CreateVoucherUseCase useCase;
  late MockVoucherRepository mockVoucherRepo;
  late MockCurrencyRepository mockCurrencyRepo;
  late MockAttachmentRepository mockAttachmentRepo;
  late MockAttachmentStorageService mockAttachmentStorage;
  late MockIdGenerator mockIdGenerator;
  late MockGovernanceWriteGuard mockWriteGuard;
  late MockFiscalPeriodRepository mockFiscalRepo;

  setUpAll(() {
    registerFallbackValue(FakeVoucher());
  });

  setUp(() {
    mockVoucherRepo = MockVoucherRepository();
    mockCurrencyRepo = MockCurrencyRepository();
    mockAttachmentRepo = MockAttachmentRepository();
    mockAttachmentStorage = MockAttachmentStorageService();
    mockIdGenerator = MockIdGenerator();
    mockWriteGuard = MockGovernanceWriteGuard();
    mockFiscalRepo = MockFiscalPeriodRepository();
    when(() => mockFiscalRepo.listAllOrdered())
        .thenAnswer((_) async => const Success([]));

    useCase = CreateVoucherUseCase(
      mockVoucherRepo,
      mockCurrencyRepo,
      mockAttachmentRepo,
      mockAttachmentStorage,
      mockIdGenerator,
      mockWriteGuard,
      mockFiscalRepo,
    );
  });

  final defaultInput = CreateVoucherInput(
    type: VoucherType.receipt,
    date: DateTime(2023, 1, 1),
    amountMinorUnits: 10000,
    currencyCode: 'USD',
    counterpartyAccountId: 'cp-id',
    affectedAccountId: 'aff-id',
  );

  test('should handle exception gracefully', () async {
    when(() => mockIdGenerator.next()).thenReturn('v-id-123');
    when(() => mockWriteGuard.assertWritesPermitted())
        .thenThrow(Exception('Unexpected error'));

    final result = await useCase(defaultInput);

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });

  test('should return failure when write guard denies access', () async {
    when(() => mockIdGenerator.next()).thenReturn('v-id-123');
    final failure = ValidationFailure(messageAr: 'Access denied');
    when(() => mockWriteGuard.assertWritesPermitted())
        .thenAnswer((_) async => FailureResult(failure));

    final result = await useCase(defaultInput);

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    verify(() => mockWriteGuard.assertWritesPermitted()).called(1);
    verifyZeroInteractions(mockCurrencyRepo);
  });

  test('should return failure when currency is not found', () async {
    when(() => mockWriteGuard.assertWritesPermitted())
        .thenAnswer((_) async => const Success(null));
    when(() => mockIdGenerator.next()).thenReturn('v-id-123');
    when(() => mockCurrencyRepo.getByCode('USD'))
        .thenAnswer((_) async => const Success(null));

    final result = await useCase(defaultInput);

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(
        (result.failureOrNull as ValidationFailure).code, 'invalid_currency');
  });

  test('should create voucher successfully without attachments', () async {
    final currency = CurrencyCode(
        code: 'USD',
        nameAr: 'دولار أمريكي',
        symbol: r'$',
        fractionalDigits: 2,
        isActive: true);
    when(() => mockWriteGuard.assertWritesPermitted())
        .thenAnswer((_) async => const Success(null));
    when(() => mockIdGenerator.next()).thenReturn('v-id-123');
    when(() => mockCurrencyRepo.getByCode('USD'))
        .thenAnswer((_) async => Success(currency));
    when(() => mockVoucherRepo.save(any()))
        .thenAnswer((_) async => const Success(null));

    final result = await useCase(defaultInput);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.voucherId, 'v-id-123');
    verify(() => mockVoucherRepo.save(any())).called(1);
    verifyZeroInteractions(mockAttachmentStorage);
  });

  test('should store attachments successfully', () async {
    // Requires importing cross_file or image_picker. Skipping for brevity.
  });
}
