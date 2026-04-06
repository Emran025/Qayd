import 'package:qayd/application/cost_centers/dtos/cost_center_details_dto.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';

final class GetCostCenterDetailsUseCase {
  const GetCostCenterDetailsUseCase(this._repository);

  final CostCenterRepository _repository;

  Future<Result<CostCenterDetailsDto>> call(String id) async {
    final centerResult = await _repository.getById(id);
    return centerResult.fold(
      (f) => FailureResult(f),
      (center) async {
        if (center == null) {
          return const FailureResult(
            ValidationFailure(
              messageAr: 'مركز التكلفة غير موجود.',
              code: 'cost_center_not_found',
            ),
          );
        }

        final dimsResult = await _repository.getAllDimensions(
          costCenterId: id,
          activeOnly: true,
        );
        final totalsResult = await _repository.getTotalsByCenter(id);
        final voucherIdsResult = await _repository.getVoucherIdsForCostCenter(
          id,
        );

        final dims = dimsResult.fold((_) => <dynamic>[], (d) => d);
        final totals = totalsResult.fold((_) => <String, int>{}, (t) => t);
        final voucherIds = voucherIdsResult.fold((_) => <String>[], (v) => v);

        return Success(
          CostCenterDetailsDto(
            center: center,
            dimensions: List.from(dims),
            totalsByCurrency: totals,
            voucherCount: voucherIds.length,
          ),
        );
      },
    );
  }
}
