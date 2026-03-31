import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/services/receipt_signing_service.dart';
import 'package:qayd/domain/value_objects/digital_signature.dart';
import 'package:qayd/domain/value_objects/signable_receipt.dart';
import 'package:qayd/domain/value_objects/signature_status.dart';
import 'package:qayd/domain/value_objects/voucher_query_filter.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';

class MatchSignatureToVoucherUseCase {
  const MatchSignatureToVoucherUseCase({
    required VoucherRepository voucherRepository,
    required ReceiptSigningService signingService,
  })  : _voucherRepository = voucherRepository,
        _signingService = signingService;

  final VoucherRepository _voucherRepository;
  final ReceiptSigningService _signingService;

  Future<Result<Voucher>> call({
    required SignableReceipt incomingReceipt,
    required String signatureHex,
    required String signerPublicKeyHex,
  }) async {
    // 1. Verify the incoming signature mathematically
    final digitalSignature = DigitalSignature.fromHex(
      signatureHex: signatureHex,
      signerPublicKeyHex: signerPublicKeyHex,
      payloadHashHex: _signingService.hashPayload(incomingReceipt.canonicalPayload).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );

    final isValid = _signingService.verifyReceiptSignature(incomingReceipt, digitalSignature);
    if (!isValid) {
      return const FailureResult(ValidationFailure(messageAr: 'التوقيع الرقمي غير صالح أو تم التلاعب بالإيصال.', code: 'invalid_signature'));
    }

    // 2. Find a matching draft voucher locally
    final draftsResult = await _voucherRepository.getAll(
       filter: const VoucherQueryFilter(state: VoucherState.draft),
    );
    
    if (draftsResult is FailureResult) {
      return FailureResult(DatabaseFailure(messageAr: 'تعذر البحث عن الإيصالات المسودة.'));
    }
    
    final drafts = (draftsResult as Success<List<Voucher>>).value;
    final matchingDrafts = drafts.where((v) => 
      v.amount.minorUnits == incomingReceipt.amountMinor &&
      v.date.toIso8601String().startsWith(incomingReceipt.dateIso)
    ).toList();

    if (matchingDrafts.isEmpty) {
      return const FailureResult(ValidationFailure(messageAr: 'لم يتم العثور على مسودة إيصال مطابقة.', code: 'no_match'));
    }

    // 3. Attach Signature
    final matchedVoucher = matchingDrafts.first;
    final updatedVoucher = matchedVoucher.attachSignature(
      signatureHex: signatureHex,
      signerPublicKeyHex: signerPublicKeyHex,
      status: SignatureStatus.verified,
      signerPhone: incomingReceipt.senderPhone, // Sender of the signature
    );

    final saveResult = await _voucherRepository.save(updatedVoucher);
    if (saveResult is FailureResult) {
       return FailureResult(DatabaseFailure(messageAr: 'تعذر حفظ الإيصال المحدث.'));
    }

    return Success(updatedVoucher);
  }
}
