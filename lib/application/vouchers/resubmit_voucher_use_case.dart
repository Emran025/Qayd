import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// Phase-A: "Resubmit" clears the red (invalid signature) look by setting the
/// signature status back to `unsigned`.
///
/// UI rule (Phase-A):
/// - Red only when `signatureStatus == invalid`
///
/// Domain note:
/// - Voucher currently doesn't support "clear signature" without adding more
///   business state. We keep dummy signature/public key values, but mark the
///   signature status as `unsigned` so the UI no longer renders it as rejected.
final class ResubmitVoucherUseCase {
  const ResubmitVoucherUseCase(this._voucherRepository, this._writeGuard);

  final VoucherRepository _voucherRepository;
  final GovernanceWriteGuard _writeGuard;
  static final String _dummySigHex = List.generate(
    64,
    (_) => '00',
  ).join(); // 128 hex chars

  static final String _dummyPubKeyHex = List.generate(
    32,
    (_) => '00',
  ).join(); // 64 hex chars

  Future<Result<void>> call({required String voucherId}) async {
    try {
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }
      final loaded = await _voucherRepository.getById(VoucherId(voucherId));
      if (loaded.isFailure) return FailureResult(loaded.failureOrNull!);
      final v = loaded.valueOrNull!;
      if (!v.state.isDraft) {
        return  FailureResult(
          ValidationFailure(
            messageAr: AppStrings.aConfirmedOrSettled1,
            code: 'voucher_resubmit_not_draft',
          ),
        );
      }

      final status =
          v.isReceipt ? AgreementStatus.accepted : AgreementStatus.underRequest;

      final resubmitted = v.attachSignature(
        signatureHex: v.senderSignatureHex ?? _dummySigHex,
        publicKeyHex: v.senderPublicKeyHex ?? _dummyPubKeyHex,
        isSender: true,
        status: status,
      );

      return _voucherRepository.save(resubmitted);
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
