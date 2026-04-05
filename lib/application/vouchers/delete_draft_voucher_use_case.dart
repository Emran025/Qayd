import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

/// Deletes a draft voucher — only when it is still in the Draft state.
///
/// For non-draft vouchers, use [WithdrawVoucherUseCase] instead
/// (non-destructive retraction preserving audit trail).
final class DeleteDraftVoucherUseCase {
  const DeleteDraftVoucherUseCase(
    this._voucherRepository,
    this._writeGuard,
  );

  final VoucherRepository _voucherRepository;
  final GovernanceWriteGuard _writeGuard;

  Future<Result<void>> call({required String voucherId}) async {
    try {
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }

      return _voucherRepository.deleteDraft(VoucherId(voucherId));
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
