import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/settings/manage_transaction_fee_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/transaction_fee_setting.dart';
import 'package:qayd/domain/repositories/transaction_fee_settings_repository.dart';

class MockTransactionFeeSettingsRepository extends Mock implements TransactionFeeSettingsRepository {}

class MockIdGenerator extends Mock implements IdGenerator {}

class FakeTransactionFeeSetting extends Fake implements TransactionFeeSetting {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTransactionFeeSetting());
  });

  late ManageTransactionFeeUseCase useCase;
  late MockTransactionFeeSettingsRepository mockRepo;
  late MockIdGenerator mockIdGenerator;

  setUp(() {
    mockRepo = MockTransactionFeeSettingsRepository();
    mockIdGenerator = MockIdGenerator();
    useCase = ManageTransactionFeeUseCase(mockRepo, mockIdGenerator);
  });

  group('ManageTransactionFeeUseCase - enableFee', () {
    test('Should complete successfully when input is valid', () async {
      when(() => mockRepo.deactivateAll())
          .thenAnswer((_) async => const Success(null));
      when(() => mockIdGenerator.next()).thenReturn('fee-1');
      when(() => mockRepo.insert(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase.enableFee(amountMinorUnits: 50, currencyCode: 'USD');

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.deactivateAll()).called(1);
      verify(() => mockIdGenerator.next()).called(1);
      final captured = verify(() => mockRepo.insert(captureAny())).captured.first as TransactionFeeSetting;
      expect(captured.id, 'fee-1');
      expect(captured.amountMinorUnits, 50);
      expect(captured.currencyCode, 'USD');
      expect(captured.isActive, isTrue);
    });

    test('Should return repository failure if deactivateAll fails', () async {
      final failure = DatabaseFailure(messageAr: 'DB Write Error');
      when(() => mockRepo.deactivateAll())
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase.enableFee(amountMinorUnits: 50, currencyCode: 'USD');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
      verifyNever(() => mockIdGenerator.next());
      verifyNever(() => mockRepo.insert(any()));
    });
    
    test('Should return exception wrapped in validation failure if unexpected error occurs', () async {
      when(() => mockRepo.deactivateAll()).thenThrow(Exception('Crash'));

      final result = await useCase.enableFee(amountMinorUnits: 50, currencyCode: 'USD');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('ManageTransactionFeeUseCase - disableFee', () {
    test('Should complete successfully', () async {
      when(() => mockRepo.deactivateAll())
          .thenAnswer((_) async => const Success(null));

      final result = await useCase.disableFee();

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.deactivateAll()).called(1);
    });
    
    test('Should return exception wrapped in validation failure if unexpected error occurs', () async {
      when(() => mockRepo.deactivateAll()).thenThrow(Exception('Crash'));

      final result = await useCase.disableFee();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });
}
