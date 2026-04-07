import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/cost_centers/activate_cost_center_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';

class MockCostCenterRepository extends Mock implements CostCenterRepository {}

class FakeCostCenter extends Fake implements CostCenter {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCostCenter());
  });

  late ActivateCostCenterUseCase useCase;
  late MockCostCenterRepository mockRepo;

  setUp(() {
    mockRepo = MockCostCenterRepository();
    useCase = ActivateCostCenterUseCase(mockRepo);
  });

  group('ActivateCostCenterUseCase', () {
    final suspendedCenter = CostCenter.restore(
      id: 'cc-1',
      name: 'Suspended Center',
      type: CostCenterType.profit,
      currencyCode: 'USD',
      isActive: false,
      isDefault: false,
      createdAt: DateTime(2023),
      suspendedAt: DateTime(2023, 5),
    );

    test('Should complete successfully when input is valid', () async {
      when(() => mockRepo.getById('cc-1'))
          .thenAnswer((_) async => Success(suspendedCenter));
      when(() => mockRepo.save(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase('cc-1');

      expect(result.isSuccess, isTrue);
      
      final captured = verify(() => mockRepo.save(captureAny())).captured.first as CostCenter;
      expect(captured.id, 'cc-1');
      expect(captured.isActive, isTrue);
      expect(captured.suspendedAt, isNull);
    });

    test('Should return validation failure if cost center does not exist', () async {
      when(() => mockRepo.getById('cc-missing'))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase('cc-missing');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).code, 'cost_center_not_found');
      
      verifyNever(() => mockRepo.save(any()));
    });

    test('Should return repository failure if getById fails', () async {
      final failure = DatabaseFailure(messageAr: 'DB Read Error');
      when(() => mockRepo.getById('cc-1'))
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase('cc-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
      
      verifyNever(() => mockRepo.save(any()));
    });
    
    test('Should return repository failure if save fails', () async {
      when(() => mockRepo.getById('cc-1'))
          .thenAnswer((_) async => Success(suspendedCenter));
      final failure = DatabaseFailure(messageAr: 'DB Write Error');
      when(() => mockRepo.save(any()))
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase('cc-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });
  });
}
