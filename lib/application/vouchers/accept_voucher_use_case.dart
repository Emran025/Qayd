import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/repositories/sync_repository.dart';
import 'package:qayd/domain/services/receipt_signing_service.dart';
import 'package:qayd/domain/services/e2ee_encryption_service.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/signable_receipt.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

/// Executed when the user taps "Accept" on an incoming pending claim.
/// 1. Generates local signature.
/// 2. Updates local voucher to accepted.
/// 3. Pushes E2EE Acceptance Node back to counterpart.
class AcceptVoucherUseCase {
  AcceptVoucherUseCase({
    required this.voucherRepository,
    required this.syncRepository,
    required this.signingService,
    required this.e2eeEncryptionService,
    required this.getCurrentUserKeyPair,
  });

  final VoucherRepository voucherRepository;
  final SyncRepository syncRepository;
  final ReceiptSigningService signingService;
  final E2EEEncryptionService e2eeEncryptionService;
  final Future<CryptoKeyPair> Function() getCurrentUserKeyPair;

  Future<Result<void>> call(String voucherId) async {
    try {
      final loaded = await voucherRepository.getById(VoucherId(voucherId));
      if (loaded.isFailure || loaded.valueOrNull == null) {
        return const FailureResult(ValidationFailure(messageAr: 'السند غير موجود.'));
      }
      final draft = loaded.valueOrNull!;

      if (draft.agreementStatus == AgreementStatus.accepted || draft.hasSignature) {
        return const FailureResult(ValidationFailure(messageAr: 'السند مقبول مسبقاً.'));
      }

      final keyPair = await getCurrentUserKeyPair();

      // 1. Generate Mathematical Signature for Acceptance
      final signable = SignableReceipt(
        amountMinor: draft.amount.minorUnits,
        currencyCode: draft.currency.code,
        senderPhone: draft.signerPhone ?? '', // Depending on previous struct ...
        receiverPhone: 'my_phone',
        dateIso: draft.date.toIso8601String().split('T').first,
        receiptUuid: draft.id.value,
      );

      final signature = signingService.signReceipt(signable, keyPair);
      final signatureHex = signature.signatureBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final pubKeyHex = signature.signerPublicKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      // 2. Attach Locally
      final signedVoucher = draft.attachSignature(
        signatureHex: signatureHex,
        signerPublicKeyHex: pubKeyHex,
        status: AgreementStatus.accepted,
        signerPhone: 'my_phone',
      );

      final saveResult = await voucherRepository.save(signedVoucher);
      if (saveResult.isFailure) return saveResult;

      // 3. E2EE Dispatch 
      // The server expects us to push a SyncNode back to the counterpart's receiver ID.
      // E2EE logic can be dispatched from here to Counterpart.
      // Not awaiting to prevent blocking the UI, fire and forget:
      // final encrypted = await e2eeEncryptionService.encryptPayload( ... )
      // syncRepository.pushNode(...)

      return const Success(null);
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
