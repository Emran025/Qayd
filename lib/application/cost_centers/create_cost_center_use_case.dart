import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


final class CreateCostCenterUseCase {
  const CreateCostCenterUseCase(this._repository, this._idGenerator);

  final CostCenterRepository _repository;
  final IdGenerator _idGenerator;

  Future<Result<CostCenter>> call({
    required String name,
    required CostCenterType type,
    required String currencyCode,
    String? description,
    int budgetMinorUnits = 0,
    List<String> categoryIds = const [],
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return  FailureResult(
        ValidationFailure(
          messageAr: AppStrings.pleaseEnterTheName,
          code: 'cost_center_name_required',
        ),
      );
    }

    final center = CostCenter.create(
      id: _idGenerator.next(),
      name: trimmed,
      type: type,
      currencyCode: currencyCode,
      createdAt: DateTime.now(),
      description: description,
      budgetMinorUnits: budgetMinorUnits,
    );

    final result = await _repository.save(center);
    if (result is FailureResult<void>) return FailureResult(result.failure);

    // Create a dimension for each selected category, linked to this center
    for (final catId in categoryIds) {
      final dim = CostCenterDimension(
        id: _idGenerator.next(),
        name: trimmed,
        category: CostCenterDimensionCategory(
            id: catId, name: ''), // Name will be filled by repo join
        costCenterId: center.id,
        isActive: true,
        isDefault: false,
        createdAt: DateTime.now(),
      );
      await _repository.saveDimension(dim);
    }

    return Success(center);
  }
}
