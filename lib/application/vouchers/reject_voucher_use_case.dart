import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// "Reject" is represented by setting the voucher agreement status to `rejected`.
class RejectVoucherUseCase {
  const RejectVoucherUseCase(
    this._voucherRepository,
    this._writeGuard,
  );

  final VoucherRepository _voucherRepository;
  final GovernanceWriteGuard _writeGuard;

  Future<Result<void>> call({
    required String voucherId,
    String? reason,
  }) async {
    try {
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }
      final loaded = await _voucherRepository.getById(
        VoucherId(voucherId),
      );
      if (loaded.isFailure) return FailureResult(loaded.failureOrNull!);
      final v = loaded.valueOrNull!;
      if (!v.state.isDraft) {
        // Only drafts can be rejected in Phase-A.
        return  FailureResult(
          ValidationFailure(
            messageAr: AppStrings.aConfirmedOrSettled,
            code: 'voucher_reject_not_draft',
          ),
        );
      }

      final rejected = v.attachRejection(
        reason: reason ?? '',
        status: AgreementStatus.rejected,
      );

      final saved = await _voucherRepository.save(rejected);
      return saved;
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
