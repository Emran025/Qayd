import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/entities/accrual_component.dart';
import 'package:qayd/domain/repositories/accrual_repository.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


final class SaveAccrualUseCase {
  const SaveAccrualUseCase(
    this._repository,
    this._idGenerator, {
    AuditLogService? auditLogService,
  }) : _auditLogService = auditLogService;
  final AccrualRepository _repository;
  final IdGenerator _idGenerator;
  final AuditLogService? _auditLogService;

  Future<Result<AccrualComponent>> call({
    String? id,
    required String name,
    String? description,
    required int totalAmountMinor,
    required String currencyCode,
    String? sourceAccountId,
    required String destinationAccountId,
    String? costCenterId,
    String? categoryId,
    required AccrualFrequency frequency,
    required DateTime startDate,
    required DateTime nextDueDate,
    bool isActive = true,
  }) async {
    final component = AccrualComponent(
      id: id ?? _idGenerator.next(),
      name: name.trim(),
      description: description?.trim(),
      totalAmountMinor: totalAmountMinor,
      currencyCode: currencyCode,
      sourceAccountId: sourceAccountId,
      destinationAccountId: destinationAccountId,
      costCenterId: costCenterId,
      categoryId: categoryId,
      frequency: frequency,
      startDate: startDate,
      nextDueDate: nextDueDate,
      isActive: isActive,
      createdAt: DateTime.now(),
    );

    if (component.name.isEmpty) {
      return  FailureResult(
          ValidationFailure(messageAr: AppStrings.pleaseEnterACommit));
    }

    final result = await _repository.save(component);
    if (result.isSuccess) {
      await _auditLogService?.log(
        entityType: 'accrual',
        entityId: component.id,
        action: id == null ? AuditAction.create : AuditAction.update,
        severity: AuditSeverity.info,
        newData: {'id': component.id, 'name': component.name, 'is_active': component.isActive},
      );
    }
    return result.fold((f) => FailureResult(f), (_) => Success(component));
  }
}
