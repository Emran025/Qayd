import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';

final class ListCostCentersUseCase {
  const ListCostCentersUseCase(this._repository);

  final CostCenterRepository _repository;

  Future<Result<List<CostCenter>>> call({bool activeOnly = false}) {
    return _repository.getAll(activeOnly: activeOnly);
  }
}
