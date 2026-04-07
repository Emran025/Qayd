import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/settings/list_currencies_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';

class MockCurrencyRepository extends Mock implements CurrencyRepository {}

void main() {
  late ListCurrenciesUseCase useCase;
  late MockCurrencyRepository mockRepo;

  setUp(() {
    mockRepo = MockCurrencyRepository();
    useCase = ListCurrenciesUseCase(mockRepo);
  });

  group('ListCurrenciesUseCase', () {
    final currencies = [
      CurrencyCode(
        code: 'USD',
        nameAr: 'دولار',
        fractionalDigits: 2,
        symbol: '\$',
      ),
    ];

    test('Should return list of currencies successfully', () async {
      when(() => mockRepo.getAll(onlyActive: any(named: 'onlyActive')))
          .thenAnswer((_) async => Success<List<CurrencyCode>>(currencies));

      final result = await useCase();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, equals(currencies));
      verify(() => mockRepo.getAll(onlyActive: false)).called(1);
    });

    test('Should return only active currencies when flag is true', () async {
      when(() => mockRepo.getAll(onlyActive: true))
          .thenAnswer((_) async => Success<List<CurrencyCode>>(currencies));

      final result = await useCase(onlyActive: true);

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.getAll(onlyActive: true)).called(1);
    });

    test('Should return repository failure if operation fails', () async {
      final failure = DatabaseFailure(messageAr: 'DB Read Error');
      when(() => mockRepo.getAll(onlyActive: any(named: 'onlyActive')))
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });
  });
}
