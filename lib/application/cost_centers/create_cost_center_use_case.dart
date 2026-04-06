import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';

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
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          messageAr: 'يرجى إدخال اسم مركز التكلفة.',
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
    return result.fold((f) => FailureResult(f), (_) => Success(center));
  }
}
