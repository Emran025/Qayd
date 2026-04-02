import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

/// "Reject" is represented by setting the voucher agreement status to `rejected`.
///
/// This matches the requested UI rule:
/// - Red when `agreementStatus == rejected`
///
/// Note: We intentionally use a deterministic dummy signature/public key.
/// This keeps the voucher in a rejected/one-sided appearance.
final class RejectVoucherUseCase {
  const RejectVoucherUseCase(
    this._voucherRepository,
    this._writeGuard,
  );

  final VoucherRepository _voucherRepository;
  final GovernanceWriteGuard _writeGuard;

  static final String _dummySigHex =
      List.generate(64, (_) => '00').join(); // 64 bytes => 128 hex chars

  static final String _dummyPubKeyHex =
      List.generate(32, (_) => '00').join(); // 32 bytes => 64 hex chars

  Future<Result<void>> call({
    required String voucherId,
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
        return const FailureResult(
          ValidationFailure(
            messageAr: 'لا يمكن رفض سند مؤكد أو مسوّى.',
            code: 'voucher_reject_not_draft',
          ),
        );
      }

      final rejected = v.attachSignature(
        signatureHex: _dummySigHex,
        signerPublicKeyHex: _dummyPubKeyHex,
        status: AgreementStatus.rejected,
      );

      final saved = await _voucherRepository.save(rejected);
      return saved;
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}

