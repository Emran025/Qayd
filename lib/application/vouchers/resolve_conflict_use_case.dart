import 'package:qayd/application/vouchers/confirm_voucher_use_case.dart';
import 'package:qayd/application/vouchers/dtos/confirm_voucher_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';

/// Resolves a reciprocal matching conflict detected during synchronization (Protocol §1).
/// 
/// If [merge] is true, the local Draft is confirmed (moving to ledger) and linked
/// to the inbound ID. If false, the inbound claim is discarded as a duplicate.
class ResolveConflictUseCase {
  ResolveConflictUseCase(
    this._notificationRepo,
    this._confirmVoucher,
  );

  final NotificationMessageRepository _notificationRepo;
  final ConfirmVoucherUseCase _confirmVoucher;

  Future<Result<void>> call({
    required String notificationId,
    required String localVoucherId,
    required bool merge,
  }) async {
    // 1. Always mark the conflict notification as processed to clear it from Inbox.
    await _notificationRepo.markProcessed(notificationId);

    if (merge) {
      // 2. Confirm the local draft so it hits the ledger.
      // This is the user's way of saying "My record is the correct one, confirm it now."
      final confirmResult = await _confirmVoucher(
        ConfirmVoucherInput(voucherId: localVoucherId),
      );
      if (confirmResult.isFailure) return FailureResult(confirmResult.failureOrNull!);
    }

    return const Success(null);
  }
}
