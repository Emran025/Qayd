import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

/// Settles a confirmed voucher — marking it as fully resolved.
///
/// Protocol §4: Upon settlement acceptance, the original voucher state is
/// updated to `settled`, and the settlement voucher acts as the closing
/// record linked via `originVoucherId`.
final class SettleVoucherUseCase {
  const SettleVoucherUseCase(
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

      final loaded = await _voucherRepository.getById(VoucherId(voucherId));
      if (loaded.isFailure) return FailureResult(loaded.failureOrNull!);
      final v = loaded.valueOrNull!;

      if (!v.state.isConfirmed) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'يمكن تسوية السند من حالة التأكيد فقط.',
            code: 'voucher_settle_not_confirmed',
          ),
        );
      }

      final settled = v.settle(DateTime.now());
      return _voucherRepository.save(settled);
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
