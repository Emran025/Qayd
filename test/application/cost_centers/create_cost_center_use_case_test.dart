import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/cost_centers/create_cost_center_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';

class MockCostCenterRepository extends Mock implements CostCenterRepository {}

class MockIdGenerator extends Mock implements IdGenerator {}

class FakeCostCenter extends Fake implements CostCenter {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCostCenter());
  });

  late CreateCostCenterUseCase useCase;
  late MockCostCenterRepository mockRepo;
  late MockIdGenerator mockIdGenerator;

  setUp(() {
    mockRepo = MockCostCenterRepository();
    mockIdGenerator = MockIdGenerator();
    useCase = CreateCostCenterUseCase(mockRepo, mockIdGenerator);
  });

  group('CreateCostCenterUseCase', () {
    test('Should complete successfully when input is valid', () async {
      when(() => mockIdGenerator.next()).thenReturn('cc-123');
      when(() => mockRepo.save(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase(
        name: 'Main Center',
        type: CostCenterType.cost,
        currencyCode: 'USD',
        description: 'Main cost center',
        budgetMinorUnits: 1000,
      );

      expect(result.isSuccess, isTrue);
      final center = result.valueOrNull!;
      expect(center.id, 'cc-123');
      expect(center.name, 'Main Center');
      expect(center.type, CostCenterType.cost);
      expect(center.currencyCode, 'USD');
      expect(center.description, 'Main cost center');
      expect(center.budgetMinorUnits, 1000);

      verify(() => mockIdGenerator.next()).called(1);
      verify(() => mockRepo.save(any())).called(1);
    });

    test('Should return validation failure if name is empty', () async {
      final result = await useCase(
        name: '   ',
        type: CostCenterType.profit,
        currencyCode: 'EUR',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).code,
          'cost_center_name_required');

      verifyNever(() => mockIdGenerator.next());
      verifyNever(() => mockRepo.save(any()));
    });

    test('Should return repository failure if the database operation fails',
        () async {
      when(() => mockIdGenerator.next()).thenReturn('cc-456');
      final failure = DatabaseFailure(messageAr: 'DB Error');
      when(() => mockRepo.save(any()))
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase(
        name: 'Another Center',
        type: CostCenterType.cost,
        currencyCode: 'GBP',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));

      verify(() => mockIdGenerator.next()).called(1);
      verify(() => mockRepo.save(any())).called(1);
    });
  });
}
