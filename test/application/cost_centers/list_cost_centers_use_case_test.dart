import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/cost_centers/list_cost_centers_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';

class MockCostCenterRepository extends Mock implements CostCenterRepository {}

void main() {
  late ListCostCentersUseCase useCase;
  late MockCostCenterRepository mockRepo;

  setUp(() {
    mockRepo = MockCostCenterRepository();
    useCase = ListCostCentersUseCase(mockRepo);
  });

  group('ListCostCentersUseCase', () {
    final mockCenters = [
      CostCenter.create(
        id: 'cc-1',
        name: 'Center 1',
        type: CostCenterType.cost,
        currencyCode: 'USD',
        createdAt: DateTime(2023),
      ),
      CostCenter.create(
        id: 'cc-2',
        name: 'Center 2',
        type: CostCenterType.profit,
        currencyCode: 'EUR',
        createdAt: DateTime(2023),
      ),
    ];

    test('Should return list of cost centers on success', () async {
      when(() => mockRepo.getAll(activeOnly: false))
          .thenAnswer((_) async => Success(mockCenters));

      final result = await useCase();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, equals(mockCenters));
    });

    test('Should pass activeOnly flag to repository correctly', () async {
      when(() => mockRepo.getAll(activeOnly: true))
          .thenAnswer((_) async => Success([mockCenters[0]]));

      final result = await useCase(activeOnly: true);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.length, 1);
      verify(() => mockRepo.getAll(activeOnly: true)).called(1);
    });

    test('Should return repository failure if operation fails', () async {
      final failure = DatabaseFailure(messageAr: 'DB Read Error');
      when(() => mockRepo.getAll(activeOnly: false))
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });
  });
}
