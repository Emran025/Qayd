import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/cost_centers/get_cost_center_details_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';

class MockCostCenterRepository extends Mock implements CostCenterRepository {}

void main() {
  late GetCostCenterDetailsUseCase useCase;
  late MockCostCenterRepository mockRepo;

  setUp(() {
    mockRepo = MockCostCenterRepository();
    useCase = GetCostCenterDetailsUseCase(mockRepo);
  });

  group('GetCostCenterDetailsUseCase', () {
    final center = CostCenter.create(
      id: 'cc-1',
      name: 'Center 1',
      type: CostCenterType.cost,
      currencyCode: 'USD',
      createdAt: DateTime(2023),
    );

    test('Should return details successfully when cost center exists',
        () async {
      when(() => mockRepo.getById('cc-1'))
          .thenAnswer((_) async => Success(center));
      when(() =>
              mockRepo.getAllDimensions(costCenterId: 'cc-1', activeOnly: true))
          .thenAnswer((_) async => const Success(<CostCenterDimension>[]));
      when(() => mockRepo.getTotalsByCenter('cc-1'))
          .thenAnswer((_) async => const Success({'USD': 1500}));
      when(() => mockRepo.getVoucherIdsForCostCenter('cc-1'))
          .thenAnswer((_) async => const Success(['v1', 'v2']));
      when(() => mockRepo.getMonthlyTrendForCenter('cc-1', months: 6))
          .thenAnswer((_) async => const Success([]));
      when(() => mockRepo.getRecentVouchersForCenter('cc-1', limit: 10))
          .thenAnswer((_) async => const Success([]));
      when(() => mockRepo.getDimensionBreakdown('cc-1'))
          .thenAnswer((_) async => const Success([]));

      final result = await useCase('cc-1');

      expect(result.isSuccess, isTrue);
      final details = result.valueOrNull!;
      expect(details.center, center);
      expect(details.dimensions, isEmpty);
      expect(details.totalsByCurrency, {'USD': 1500});
      expect(details.voucherCount, 2);
    });

    test('Should return validation failure if cost center does not exist',
        () async {
      when(() => mockRepo.getById('cc-missing'))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase('cc-missing');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).code,
          'cost_center_not_found');

      verifyNever(() => mockRepo.getAllDimensions(
          costCenterId: any(named: 'costCenterId'),
          activeOnly: any(named: 'activeOnly')));
    });

    test('Should return repository failure if getById fails', () async {
      final failure = DatabaseFailure(messageAr: 'DB Error');
      when(() => mockRepo.getById('cc-1'))
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase('cc-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });
  });
}
