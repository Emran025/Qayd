import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/settings/get_base_currency_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';

class MockCurrencyRepository extends Mock implements CurrencyRepository {}

void main() {
  late GetBaseCurrencyUseCase useCase;
  late MockCurrencyRepository mockRepo;

  setUp(() {
    mockRepo = MockCurrencyRepository();
    useCase = GetBaseCurrencyUseCase(mockRepo);
  });

  group('GetBaseCurrencyUseCase', () {
    test('Should return base currency successfully', () async {
      when(() => mockRepo.getBaseCurrencyCode())
          .thenAnswer((_) async => const Success('USD'));

      final result = await useCase();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 'USD');
    });

    test('Should return repository failure if operation fails', () async {
      final failure = DatabaseFailure(messageAr: 'DB Read Error');
      when(() => mockRepo.getBaseCurrencyCode())
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });
  });
}
