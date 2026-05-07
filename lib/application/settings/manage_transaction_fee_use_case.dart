import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/fee_calculation_type.dart';
import 'package:qayd/domain/entities/transaction_fee_setting.dart';
import 'package:qayd/domain/entities/transaction_fee_type.dart';
import 'package:qayd/domain/repositories/transaction_fee_settings_repository.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';

class ManageTransactionFeeUseCase {
  ManageTransactionFeeUseCase(
    this._repo,
    this._idGen, {
    AuditLogService? auditLogService,
  }) : _auditLogService = auditLogService;

  final TransactionFeeSettingsRepository _repo;
  final IdGenerator _idGen;
  final AuditLogService? _auditLogService;

  /// Enables a transaction fee by deactivating all old ones and appending a new one.
  Future<Result<void>> enableFee({
    required int value,
    required FeeCalculationType calculationType,
    required TransactionFeeType type,
  }) async {
    try {
      final deactivateRes = await _repo.deactivateAll(type);
      if (deactivateRes.isFailure) {
        return FailureResult(deactivateRes.failureOrNull!);
      }

      final setting = TransactionFeeSetting(
        id: _idGen.next(),
        value: value,
        calculationType: calculationType,
        type: type,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final insertResult = await _repo.insert(setting);
      if (insertResult.isSuccess) {
        await _auditLogService?.log(
          entityType: 'transaction_fee_setting',
          entityId: setting.id,
          action: AuditAction.create,
          severity: AuditSeverity.info,
          newData: {
            'id': setting.id,
            'type': setting.type.name,
            'value': setting.value,
            'calc_type': setting.calculationType.name,
          },
        );
      }
      return insertResult;
    } catch (e) {
      return FailureResult(
          ValidationFailure(messageAr: 'فشل في تفعيل الرسوم: $e'));
    }
  }

  /// Disables the transaction fee globally.
  Future<Result<void>> disableFee(TransactionFeeType type) async {
    try {
      final result = await _repo.deactivateAll(type);
      if (result.isSuccess) {
        await _auditLogService?.log(
          entityType: 'transaction_fee_setting',
          entityId: type.name,
          action: AuditAction.update,
          severity: AuditSeverity.warning,
          newData: {'type': type.name, 'is_active': false},
        );
      }
      return result;
    } catch (e) {
      return FailureResult(
          ValidationFailure(messageAr: 'فشل في تعطيل الرسوم: $e'));
    }
  }
}
