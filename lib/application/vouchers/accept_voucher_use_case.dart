import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/domain/entities/sync_node.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/repositories/sync_repository.dart';
import 'package:qayd/domain/services/receipt_signing_service.dart';
import 'package:qayd/domain/services/e2ee_encryption_service.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/signable_receipt.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/services/entry_generator.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/entry_id.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:uuid/uuid.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// Executed when the user taps "Accept" on an incoming pending claim.
///
/// Protocol §1 — Signature Execution Post-Matching:
/// 1. Resolves the current user's phone from LicenseVault.
/// 2. Generates an Ed25519 signature over the canonical payload.
/// 3. Attaches the signature locally and marks voucher as accepted.
/// 4. Dispatches an E2EE acceptance SyncNode back to the counterparty.
class AcceptVoucherUseCase {
  AcceptVoucherUseCase({
    required this.voucherRepository,
    required this.accountRepository,
    required this.syncRepository,
    required this.signingService,
    required this.e2eeEncryptionService,
    required this.getCurrentUserKeyPair,
    required this.licenseVault,
    required this.entryGenerator,
    required this.idGenerator,
  });

  final VoucherRepository voucherRepository;
  final AccountRepository accountRepository;
  final SyncRepository syncRepository;
  final ReceiptSigningService signingService;
  final E2EEEncryptionService e2eeEncryptionService;
  final Future<CryptoKeyPair> Function() getCurrentUserKeyPair;
  final LicenseVault licenseVault;
  final EntryGenerator entryGenerator;
  final IdGenerator idGenerator;

  Future<Result<void>> call(String voucherId) async {
    try {
      final loaded = await voucherRepository.getById(VoucherId(voucherId));
      if (loaded.isFailure || loaded.valueOrNull == null) {
        return  FailureResult(
            ValidationFailure(messageAr: AppStrings.theBondDoesNot));
      }
      final draft = loaded.valueOrNull!;

      if (draft.receiverStatus == AgreementStatus.accepted) {
        return  FailureResult(
            ValidationFailure(messageAr: AppStrings.theBondIsPreaccepted));
      }

      // Resolve current user's phone from license data.
      final licenseData = await licenseVault.readLicenseData();
      final myPhone = licenseData?['phone'] as String? ?? '';

      // Resolve counterparty's phone for canonical payload.
      final counterpartyParty =
          await accountRepository.getPartyDetails(draft.counterpartyId);
      final counterpartyPhone =
          counterpartyParty.valueOrNull?.phoneNumber ?? draft.signerPhone ?? '';

      final keyPair = await getCurrentUserKeyPair();

      // 1. Generate Mathematical Signature for Acceptance.
      final signable = SignableReceipt(
        amountMinor: draft.amount.minorUnits,
        currencyCode: draft.currency.code,
        senderPhone: counterpartyPhone,
        receiverPhone: myPhone,
        dateIso: draft.date.toIso8601String().split('T').first,
        receiptUuid: draft.id.value,
      );

      final signature = signingService.signReceipt(signable, keyPair);
      final signatureHex = signature.signatureHex;
      final pubKeyHex = signature.signerPublicKeyHex;

      // 2. Attach Locally and Confirm.
      var signedVoucher = draft.attachSignature(
        signatureHex: signatureHex,
        publicKeyHex: pubKeyHex,
        isSender: false, // The user is accepting an inbound claim.
        status: AgreementStatus.accepted,
        signerPhone: myPhone,
      );

      // Auto-confirm state to record in local ledger.
      signedVoucher = signedVoucher.confirm(DateTime.now());

      // Generate Ledger Entries.
      final now = DateTime.now();
      final transactionId = TransactionId(idGenerator.next());
      final debitId = EntryId(idGenerator.next());
      final creditId = EntryId(idGenerator.next());

      final entries = entryGenerator.generateForConfirmedVoucher(
        voucher: signedVoucher,
        transactionId: transactionId,
        debitEntryId: debitId,
        creditEntryId: creditId,
        ledgerCreatedAt: now,
      );

      final saveResult = await voucherRepository.saveWithLedgerEntries(
        voucher: signedVoucher,
        ledgerEntries: entries,
      );
      if (saveResult.isFailure) return saveResult;

      // 3. E2EE Dispatch — push acceptance SyncNode back to counterparty.
      // Fire-and-forget to avoid blocking the UI; the accounting transaction is already complete locally.
      _dispatchAcceptanceSyncNode(
        voucherId: voucherId,
        signatureHex: signatureHex,
        signerPublicKeyHex: pubKeyHex,
        signerPhone: myPhone,
        counterpartyId: draft.counterpartyId,
        myKeyPair: keyPair,
        counterpartyParty: counterpartyParty.valueOrNull,
      ).ignore();

      return const Success(null);
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }

  /// Dispatches an encrypted acceptance node to the counterparty (fire-and-forget).
  Future<void> _dispatchAcceptanceSyncNode({
    required String voucherId,
    required String signatureHex,
    required String signerPublicKeyHex,
    required String signerPhone,
    required AccountId counterpartyId,
    required CryptoKeyPair myKeyPair,
    required dynamic counterpartyParty,
  }) async {
    try {
      final counterpartyPubKey = counterpartyParty?.currentPublicKeyHex;
      if (counterpartyPubKey == null) return;

      final rawPayload = {
        'voucher_id': voucherId,
        'receiver_signature_hex': signatureHex,
        'receiver_public_key_hex': signerPublicKeyHex,
        'signer_phone': signerPhone,
        'sender_status': 'accepted',
        'receiver_status': 'accepted',
      };

      final encrypted = await e2eeEncryptionService.encryptPayload(
        rawPayload: rawPayload,
        senderKeyPair: myKeyPair,
        receiverPublicKeyHex: counterpartyPubKey,
      );

      final licenseData = await licenseVault.readLicenseData();
      final myUserId = (licenseData?['id'] as num?)?.toInt() ?? 0;

      // Resolve counterparty's server-side user ID.
      final serverAccountId = counterpartyParty?.serverAccountId ?? 0;

      final node = SyncNode(
        id: const Uuid().v4(),
        senderId: myUserId,
        receiverId: serverAccountId,
        eventType: SyncEventType.acceptance,
        encryptedPayload: encrypted,
        syncState: 'pending',
        clientTimestamp: DateTime.now(),
      );

      await syncRepository.pushNode(node);
    } catch (_) {
      // Non-fatal: the counterparty will discover via pull sync.
    }
  }
}
