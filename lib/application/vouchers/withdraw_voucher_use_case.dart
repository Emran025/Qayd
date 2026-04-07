import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/application/sync/sync_event_dispatcher.dart';

/// Withdraws (سحب) a voucher — non-destructive retraction.
///
/// Protocol §2.A: A voucher can be withdrawn if it is still in Draft,
/// UnderRequest, or Rejected states. The record remains in the database
/// for audit integrity but is flagged as withdrawn. It disappears from
/// the recipient's "Inbox" and is moved to a local "Archive" for the creator.
final class WithdrawVoucherUseCase {
  const WithdrawVoucherUseCase(
    this._voucherRepository,
    this._writeGuard, {
    SyncEventDispatcher? syncEventDispatcher,
  }) : _syncEventDispatcher = syncEventDispatcher;

  final VoucherRepository _voucherRepository;
  final GovernanceWriteGuard _writeGuard;
  final SyncEventDispatcher? _syncEventDispatcher;

  Future<Result<void>> call({required String voucherId}) async {
    try {
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }

      final loaded = await _voucherRepository.getById(VoucherId(voucherId));
      if (loaded.isFailure) return FailureResult(loaded.failureOrNull!);
      final v = loaded.valueOrNull!;

      if (!v.state.canWithdraw) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'لا يمكن سحب سند مؤكد أو مسوّى.',
            code: 'voucher_withdraw_not_allowed',
          ),
        );
      }

      final withdrawn = v.withdraw(DateTime.now());
      final saved = await _voucherRepository.save(withdrawn);
      if (saved.isSuccess && _syncEventDispatcher != null) {
        // §5.A: Enqueue withdrawal into local outbox
        await _syncEventDispatcher!.dispatchVoucherWithdrawal(withdrawn);
      }
      return saved;
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
