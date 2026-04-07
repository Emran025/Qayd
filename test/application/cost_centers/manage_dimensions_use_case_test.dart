import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/cost_centers/manage_dimensions_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';

class MockCostCenterRepository extends Mock implements CostCenterRepository {}

class MockIdGenerator extends Mock implements IdGenerator {}

class FakeCostCenterDimension extends Fake implements CostCenterDimension {}

class FakeCostCenterDimensionCategory extends Fake implements CostCenterDimensionCategory {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCostCenterDimension());
    registerFallbackValue(FakeCostCenterDimensionCategory());
  });

  late ManageDimensionsUseCase useCase;
  late MockCostCenterRepository mockRepo;
  late MockIdGenerator mockIdGenerator;

  setUp(() {
    mockRepo = MockCostCenterRepository();
    mockIdGenerator = MockIdGenerator();
    useCase = ManageDimensionsUseCase(mockRepo, mockIdGenerator);
  });

  group('ManageDimensionsUseCase - addDimension', () {
    final category = CostCenterDimensionCategory(id: 'cat-1', name: 'Project');

    test('Should complete successfully when input is valid', () async {
      when(() => mockIdGenerator.next()).thenReturn('dim-123');
      when(() => mockRepo.saveDimension(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase.addDimension(
        name: 'Project A',
        category: category,
        costCenterId: 'cc-1',
      );

      expect(result.isSuccess, isTrue);
      final dim = result.valueOrNull!;
      expect(dim.id, 'dim-123');
      expect(dim.name, 'Project A');
      expect(dim.category, category);
      expect(dim.costCenterId, 'cc-1');
      
      verify(() => mockIdGenerator.next()).called(1);
      verify(() => mockRepo.saveDimension(any())).called(1);
    });

    test('Should return validation failure if name is empty', () async {
      final result = await useCase.addDimension(
        name: '   ',
        category: category,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).code, 'dimension_name_required');
      
      verifyNever(() => mockIdGenerator.next());
      verifyNever(() => mockRepo.saveDimension(any()));
    });
    
    test('Should return repository failure if save fails', () async {
      when(() => mockIdGenerator.next()).thenReturn('dim-456');
      final failure = DatabaseFailure(messageAr: 'DB Error');
      when(() => mockRepo.saveDimension(any()))
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase.addDimension(
        name: 'Project B',
        category: category,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });
  });

  group('ManageDimensionsUseCase - addCategory', () {
    test('Should complete successfully when input is valid', () async {
      when(() => mockIdGenerator.next()).thenReturn('cat-123');
      when(() => mockRepo.saveCategory(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase.addCategory(
        name: 'Region',
        iconName: 'map',
      );

      expect(result.isSuccess, isTrue);
      final cat = result.valueOrNull!;
      expect(cat.id, 'cat-123');
      expect(cat.name, 'Region');
      expect(cat.iconName, 'map');
      
      verify(() => mockIdGenerator.next()).called(1);
      verify(() => mockRepo.saveCategory(any())).called(1);
    });

    test('Should return validation failure if name is empty', () async {
      final result = await useCase.addCategory(
        name: '   ',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((result.failureOrNull as ValidationFailure).code, 'category_name_required');
      
      verifyNever(() => mockIdGenerator.next());
      verifyNever(() => mockRepo.saveCategory(any()));
    });
  });

  group('ManageDimensionsUseCase - attachVoucherToCenter', () {
    test('Should attach successfully', () async {
      when(() => mockRepo.attachVoucher(
          voucherId: 'v-1', costCenterId: 'cc-1', dimensionIds: ['dim-1']))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase.attachVoucherToCenter(
        voucherId: 'v-1',
        costCenterId: 'cc-1',
        dimensionIds: ['dim-1'],
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.attachVoucher(
          voucherId: 'v-1', costCenterId: 'cc-1', dimensionIds: ['dim-1'])).called(1);
    });
  });
}
