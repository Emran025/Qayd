import 'package:qayd/application/identity/setup_identity_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_invoice.dart';
import 'package:qayd/domain/entities/pos_invoice_payment.dart';
import 'package:qayd/domain/services/pos_invoice_signing_service.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

/// Signs an immutable posted POS invoice. Persistence is intentionally owned by
/// the atomic sale coordinator in the completion flow.
final class SignPosInvoiceUseCase {
  const SignPosInvoiceUseCase({
    required PosInvoiceSigningService signingService,
    required SetupIdentityUseCase setupIdentityUseCase,
  })  : _signingService = signingService,
        _setupIdentityUseCase = setupIdentityUseCase;

  final PosInvoiceSigningService _signingService;
  final SetupIdentityUseCase _setupIdentityUseCase;

  Future<Result<PosInvoice>> call({
    required PosInvoice invoice,
    required List<PosInvoicePayment> payments,
    required DateTime signedAt,
  }) async {
    if (invoice.status.isDraft) {
      return FailureResult(
        ValidationFailure(
          messageAr: 'لا يمكن توقيع فاتورة مسودة قبل ترحيلها',
          code: 'pos_invoice_not_posted',
        ),
      );
    }
    final keyPair = await _setupIdentityUseCase.getKeyPair();
    if (keyPair == null) {
      return FailureResult(
        ValidationFailure(
          messageAr: AppStrings.identityNotSetup,
          code: 'identity_missing',
        ),
      );
    }
    try {
      final signature = _signingService.sign(
        invoice: invoice,
        payments: payments,
        keyPair: keyPair,
        signedAt: signedAt,
      );
      return Success(invoice.attachSignature(signature, signedAt));
    } catch (error) {
      return FailureResult(
        ValidationFailure(
          messageAr: 'تعذر توقيع فاتورة POS: $error',
          code: 'pos_invoice_signature_failed',
        ),
      );
    }
  }
}
