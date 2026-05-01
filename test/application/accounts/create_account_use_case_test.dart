import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/accounts/create_account_use_case.dart';
import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/entities/party_details.dart';
import 'package:qayd/data/security/license_vault.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class FakeAccount extends Fake implements Account {}

class FakePartyDetails extends Fake implements PartyDetails {}

class MockIdGenerator extends Mock implements IdGenerator {}

class MockGovernanceWriteGuard extends Mock implements GovernanceWriteGuard {}

class MockLicenseVault extends Mock implements LicenseVault {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAccount());
    registerFallbackValue(FakePartyDetails());
  });

  late CreateAccountUseCase useCase;
  late MockAccountRepository mockAccountRepo;
  late MockIdGenerator mockIdGenerator;
  late MockGovernanceWriteGuard mockWriteGuard;
  late MockLicenseVault mockLicenseVault;

  setUp(() {
    mockAccountRepo = MockAccountRepository();
    mockIdGenerator = MockIdGenerator();
    mockWriteGuard = MockGovernanceWriteGuard();
    mockLicenseVault = MockLicenseVault();

    when(() => mockLicenseVault.readLicenseData())
        .thenAnswer((_) async => {'phone': '966500000000'});

    useCase = CreateAccountUseCase(
      mockAccountRepo,
      mockIdGenerator,
      mockWriteGuard,
      mockLicenseVault,
    );
  });

  final defaultInput = CreateAccountInput(
    name: 'Test Account',
    rootStandardKind: StandardAccountClassificationKind.payables,
  );

  test('should block creation if write guard fails', () async {
    final failure = ValidationFailure(messageAr: 'Denied');
    when(() => mockWriteGuard.assertWritesPermitted())
        .thenAnswer((_) async => FailureResult(failure));

    final result = await useCase(defaultInput);

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, equals(failure));
  });

  test('should create account successfully', () async {
    when(() => mockWriteGuard.assertWritesPermitted())
        .thenAnswer((_) async => const Success(null));
    when(() => mockIdGenerator.next()).thenReturn('acc-123');
    when(() => mockAccountRepo.save(any()))
        .thenAnswer((_) async => const Success(null));

    final result = await useCase(defaultInput);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.accountId, 'acc-123');
  });

  test('should return failure if phone number is not unique', () async {
    final inputWithPhone = CreateAccountInput(
      name: 'Phone Test',
      phoneNumber: '1234567890',
      rootStandardKind: StandardAccountClassificationKind.payables,
    );

    when(() => mockWriteGuard.assertWritesPermitted())
        .thenAnswer((_) async => const Success(null));
    when(() => mockAccountRepo.findAccountByPhone('9661234567890'))
        .thenAnswer((_) async => Success(AccountId('existing-id')));

    final result = await useCase(inputWithPhone);

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect((result.failureOrNull as ValidationFailure).messageAr,
        'يوجد حساب مسجل مسبقاً برقم الهاتف هذا.');
  });
}
