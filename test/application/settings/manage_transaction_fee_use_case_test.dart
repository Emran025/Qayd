import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/settings/manage_transaction_fee_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/fee_calculation_type.dart';
import 'package:qayd/domain/entities/transaction_fee_setting.dart';
import 'package:qayd/domain/entities/transaction_fee_type.dart';
import 'package:qayd/domain/repositories/transaction_fee_settings_repository.dart';

class MockTransactionFeeSettingsRepository extends Mock
    implements TransactionFeeSettingsRepository {}

class MockIdGenerator extends Mock implements IdGenerator {}

class FakeTransactionFeeSetting extends Fake implements TransactionFeeSetting {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTransactionFeeSetting());
    registerFallbackValue(TransactionFeeType.tripartite);
    registerFallbackValue(FeeCalculationType.fixed);
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
      when(() => mockRepo.deactivateAll(any()))
          .thenAnswer((_) async => const Success(null));
      when(() => mockIdGenerator.next()).thenReturn('fee-1');
      when(() => mockRepo.insert(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase.enableFee(
        value: 50,
        calculationType: FeeCalculationType.fixed,
        type: TransactionFeeType.tripartite,
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.deactivateAll(any())).called(1);
      verify(() => mockIdGenerator.next()).called(1);
      final captured = verify(() => mockRepo.insert(captureAny()))
          .captured
          .first as TransactionFeeSetting;
      expect(captured.id, 'fee-1');
      expect(captured.value, 50);
      expect(captured.calculationType, FeeCalculationType.fixed);
      expect(captured.isActive, isTrue);
    });
  });

  group('ManageTransactionFeeUseCase - disableFee', () {
    test('Should complete successfully', () async {
      when(() => mockRepo.deactivateAll(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase.disableFee(TransactionFeeType.tripartite);

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.deactivateAll(any())).called(1);
    });
  });
}
