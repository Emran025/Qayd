import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';

final class ManageDimensionsUseCase {
  const ManageDimensionsUseCase(this._repository, this._idGenerator);

  final CostCenterRepository _repository;
  final IdGenerator _idGenerator;

  Future<Result<CostCenterDimension>> addDimension({
    required String name,
    required CostCenterDimensionCategory category,
    String? costCenterId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          messageAr: 'يرجى إدخال اسم البُعد.',
          code: 'dimension_name_required',
        ),
      );
    }

    final dimension = CostCenterDimension(
      id: _idGenerator.next(),
      name: trimmed,
      category: category,
      costCenterId: costCenterId,
      isDefault: false,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final result = await _repository.saveDimension(dimension);
    return result.fold((f) => FailureResult(f), (_) => Success(dimension));
  }

  Future<Result<void>> deleteDimension(String id) =>
      _repository.deleteDimension(id);

  Future<Result<List<CostCenterDimension>>> listDimensions({
    String? costCenterId,
  }) {
    return _repository.getAllDimensions(
      costCenterId: costCenterId,
      activeOnly: false,
    );
  }

  Future<Result<List<CostCenterDimensionCategory>>> listCategories() {
    return _repository.getAllCategories();
  }

  Future<Result<CostCenterDimensionCategory>> addCategory({
    required String name,
    String? iconName,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          messageAr: 'يرجى إدخال اسم التصنيف.',
          code: 'category_name_required',
        ),
      );
    }

    final category = CostCenterDimensionCategory(
      id: _idGenerator.next(),
      name: trimmed,
      iconName: iconName,
    );

    final result = await _repository.saveCategory(category);
    return result.fold((f) => FailureResult(f), (_) => Success(category));
  }

  Future<Result<void>> attachVoucherToCenter({
    required String voucherId,
    required String costCenterId,
    List<String> dimensionIds = const [],
  }) {
    return _repository.attachVoucher(
      voucherId: voucherId,
      costCenterId: costCenterId,
      dimensionIds: dimensionIds,
    );
  }

  Future<Result<void>> detachVoucherFromCenter({
    required String voucherId,
    required String costCenterId,
  }) {
    return _repository.detachVoucher(
      voucherId: voucherId,
      costCenterId: costCenterId,
    );
  }
}
