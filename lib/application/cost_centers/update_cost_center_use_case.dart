import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


final class UpdateCostCenterUseCase {
  const UpdateCostCenterUseCase(this._repository);

  final CostCenterRepository _repository;

  Future<Result<void>> call({
    required String id,
    String? name,
    CostCenterType? type,
    String? currencyCode,
    String? description,
    int? budgetMinorUnits,
    bool? isActive,
  }) async {
    final existingResult = await _repository.getById(id);
    return existingResult.fold(
      (f) => FailureResult(f),
      (existing) async {
        if (existing == null) {
          return const FailureResult(
            ValidationFailure(
              messageAr: AppStringsAr.costCenterDoesNot,
              code: 'cost_center_not_found',
            ),
          );
        }

        final updated = existing.copyWith(
          name: name ?? existing.name,
          type: type ?? existing.type,
          currencyCode: currencyCode ?? existing.currencyCode,
          description: description ?? existing.description,
          budgetMinorUnits: budgetMinorUnits ?? existing.budgetMinorUnits,
          isActive: isActive ?? existing.isActive,
        );

        return _repository.save(updated);
      },
    );
  }
}
