import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


final class SuspendCostCenterUseCase {
  const SuspendCostCenterUseCase(this._repository);

  final CostCenterRepository _repository;

  Future<Result<void>> call(String id) async {
    final result = await _repository.getById(id);
    return result.fold(
      (f) => FailureResult(f),
      (center) async {
        if (center == null) {
          return const FailureResult(
            ValidationFailure(
              messageAr: AppStringsAr.costCenterDoesNot,
              code: 'cost_center_not_found',
            ),
          );
        }
        final suspended = center.suspend(DateTime.now());
        return _repository.save(suspended);
      },
    );
  }
}
