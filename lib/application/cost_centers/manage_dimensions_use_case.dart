import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


final class ManageDimensionsUseCase {
  const ManageDimensionsUseCase(
    this._repository,
    this._idGenerator, {
    AuditLogService? auditLogService,
  }) : _auditLogService = auditLogService;

  final CostCenterRepository _repository;
  final IdGenerator _idGenerator;
  final AuditLogService? _auditLogService;

  Future<Result<CostCenterDimension>> addDimension({
    required String name,
    required CostCenterDimensionCategory category,
    String? costCenterId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return  FailureResult(
        ValidationFailure(
          messageAr: AppStrings.pleaseEnterADimension,
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
    if (result.isSuccess) {
      await _auditLogService?.log(
        entityType: 'cost_center_dimension',
        entityId: dimension.id,
        action: AuditAction.create,
        severity: AuditSeverity.info,
        newData: {'id': dimension.id, 'name': dimension.name},
      );
    }
    return result.fold((f) => FailureResult(f), (_) => Success(dimension));
  }

  Future<Result<void>> deleteDimension(String id) async {
    final result = await _repository.deleteDimension(id);
    if (result.isSuccess) {
      await _auditLogService?.log(
        entityType: 'cost_center_dimension',
        entityId: id,
        action: AuditAction.delete,
        severity: AuditSeverity.warning,
        oldData: {'id': id},
      );
    }
    return result;
  }

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
      return  FailureResult(
        ValidationFailure(
          messageAr: AppStrings.pleaseEnterTheCategory,
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
    if (result.isSuccess) {
      await _auditLogService?.log(
        entityType: 'cost_center_dimension',
        entityId: category.id,
        action: AuditAction.create,
        severity: AuditSeverity.info,
        newData: {'id': category.id, 'name': category.name},
      );
    }
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
