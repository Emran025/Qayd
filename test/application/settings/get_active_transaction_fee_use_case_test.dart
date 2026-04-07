import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/settings/get_active_transaction_fee_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/transaction_fee_setting.dart';
import 'package:qayd/domain/repositories/transaction_fee_settings_repository.dart';

class MockTransactionFeeSettingsRepository extends Mock implements TransactionFeeSettingsRepository {}

void main() {
  late GetActiveTransactionFeeUseCase useCase;
  late MockTransactionFeeSettingsRepository mockRepo;

  setUp(() {
    mockRepo = MockTransactionFeeSettingsRepository();
    useCase = GetActiveTransactionFeeUseCase(mockRepo);
  });

  group('GetActiveTransactionFeeUseCase', () {
    final activeFee = TransactionFeeSetting(
      id: 'fee-1',
      amountMinorUnits: 50,
      currencyCode: 'USD',
      isActive: true,
      createdAt: DateTime.now(),
    );

    test('Should return active fee successfully', () async {
      when(() => mockRepo.getActive())
          .thenAnswer((_) async => Success(activeFee));

      final result = await useCase();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, equals(activeFee));
    });

    test('Should return repository failure if operation fails', () async {
      final failure = DatabaseFailure(messageAr: 'DB Read Error');
      when(() => mockRepo.getActive())
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });
  });
}
