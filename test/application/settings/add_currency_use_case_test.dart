import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/settings/add_currency_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';

class MockCurrencyRepository extends Mock implements CurrencyRepository {}

class FakeCurrencyCode extends Fake implements CurrencyCode {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCurrencyCode());
  });

  late AddCurrencyUseCase useCase;
  late MockCurrencyRepository mockRepo;

  setUp(() {
    mockRepo = MockCurrencyRepository();
    useCase = AddCurrencyUseCase(mockRepo);
  });

  group('AddCurrencyUseCase', () {
    final currency = CurrencyCode(
      code: 'JOD',
      nameAr: 'دينار أردني',
      fractionalDigits: 3,
      symbol: 'JD',
    );

    test('Should complete successfully when input is valid', () async {
      when(() => mockRepo.save(any(), isPredefined: any(named: 'isPredefined')))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase(currency);

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.save(currency, isPredefined: false)).called(1);
    });

    test('Should return repository failure if the database operation fails', () async {
      final failure = DatabaseFailure(messageAr: 'DB Write Error');
      when(() => mockRepo.save(any(), isPredefined: any(named: 'isPredefined')))
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase(currency);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });
  });
}
