import 'package:flutter/foundation.dart';
import 'package:qayd/application/failure_mapping.dart';

import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/services/signature_verification_engine.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';

/// Outcome of incoming voucher verification.
class VerificationOutcome {
  const VerificationOutcome({
    required this.voucherId,
    required this.status,
    this.matchedKeyHex,
    this.failureReason,
  });

  final String voucherId;
  final AgreementStatus status;
  final String? matchedKeyHex;
  final String? failureReason;

  bool get isVerified => status == AgreementStatus.accepted;
  bool get isSuspended => status == AgreementStatus.unverified;
}

/// Implements Protocol §5 — Voucher Signature Verification Protocol.
///
/// When a signed voucher arrives (via QR, server, or SMS), this use case:
/// 1. Maps it into the affected account.
/// 2. Runs the cross-vector verification engine.
/// 3. Commits: Accepted (verified) or Suspended/Unapproved (unverified).
///
/// The voucher is always stored, but flagged accordingly:
/// - **Success:** Committed with `AgreementStatus.accepted`.
/// - **Failure:** Stored as `AgreementStatus.unverified` — suspended claim.
class VerifyIncomingVoucherUseCase {
  const VerifyIncomingVoucherUseCase({
    required this.voucherRepository,
    required this.accountRepository,
    required this.verificationEngine,
    required this.licenseVault,
  });

  final VoucherRepository voucherRepository;
  final AccountRepository accountRepository;
  final SignatureVerificationEngine verificationEngine;
  final LicenseVault licenseVault;

  /// Verifies and stores an incoming voucher.
  ///
  /// [voucher] — the incoming voucher entity (already constructed from payload).
  /// [senderPhone] — phone of the party who signed the voucher.
  /// [senderEmail] — email of the party (optional fallback for identity).
  Future<Result<VerificationOutcome>> call({
    required Voucher voucher,
    required String senderPhone,
    String? senderEmail,
  }) async {
    try {
      // Resolve the current user's phone.
      final licenseData = await licenseVault.readLicenseData();
      final myPhone = licenseData?['phone'] as String? ?? '';

      // Run the cross-vector verification engine.
      final result = await verificationEngine.verifyIncomingVoucher(
        voucher: voucher,
        senderPhone: senderPhone,
        senderEmail: senderEmail,
        myPhone: myPhone,
      );

      AgreementStatus finalStatus;
      String? failureReason;

      if (result.isVerified) {
        // §5.5 Success State — voucher is safely committed.
        finalStatus = AgreementStatus.accepted;
        debugPrint(
          'Voucher [${voucher.id.value}] verified against key: ${result.matchedKeyHex}',
        );
      } else if (result.isAccountNotFound) {
        // §5.6 Failure: account not found — user is notified.
        finalStatus = AgreementStatus.unverified;
        failureReason = 'الحساب غير موجود. لا يمكن التحقق من التوقيع.';
        debugPrint(
          'Voucher [${voucher.id.value}] SUSPENDED: sender account not found.',
        );
      } else {
        // §5.6 Failure: signature doesn't match — suspended as unapproved claim.
        finalStatus = AgreementStatus.unverified;
        failureReason =
            'التوقيع لا ينتمي إلى هذا الحساب. يبقى معلقاً كإدعاء لم يقم ذلك الحساب الطرف بالموافقة عليه.';
        debugPrint(
          'Voucher [${voucher.id.value}] SUSPENDED: signature mismatch (${result.failureReason}).',
        );
      }

      // Store the voucher with the determined status.
      final storedVoucher = voucher.attachSignature(
        signatureHex: voucher.senderSignatureHex ?? '',
        publicKeyHex: voucher.senderPublicKeyHex ?? '',
        isSender:
            true, // The counterparty (the one who sent this) is the creator/sender.
        status: finalStatus,
        signerPhone: senderPhone,
      );

      final saveResult = await voucherRepository.save(storedVoucher);
      if (saveResult.isFailure) {
        return FailureResult(saveResult.failureOrNull!);
      }

      return Success(VerificationOutcome(
        voucherId: voucher.id.value,
        status: finalStatus,
        matchedKeyHex: result.matchedKeyHex,
        failureReason: failureReason,
      ));
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
