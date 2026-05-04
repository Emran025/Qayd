import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


final class ActivateCostCenterUseCase {
  const ActivateCostCenterUseCase(this._repository);

  final CostCenterRepository _repository;

  Future<Result<void>> call(String id) async {
    final result = await _repository.getById(id);
    return result.fold(
      (f) => FailureResult(f),
      (center) async {
        if (center == null) {
          return  FailureResult(
            ValidationFailure(
              messageAr: AppStrings.costCenterDoesNot,
              code: 'cost_center_not_found',
            ),
          );
        }
        final activated = center.activate();
        return _repository.save(activated);
      },
    );
  }
}
