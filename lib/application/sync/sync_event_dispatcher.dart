import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/repositories/outbox_dao.dart';
import 'package:qayd/domain/entities/collateral.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/services/e2ee_encryption_service.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/core/utils/text_sanitizer.dart';
import 'package:uuid/uuid.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


/// Centralizes the encryption and enqueuing of financial mutations into the Local Outbox.
///
/// Protocol §5.A: Every voucher creation, state transition, signature attachment,
/// or metadata mutation is appended here before any network operation is attempted.
///
/// This service ensures all outbound synchronization events are E2EE-encrypted
/// strictly for the relevant counterparty's public key.
class SyncEventDispatcher {
  SyncEventDispatcher({
    required this.outboxDao,
    required this.e2eeEncryptionService,
    required this.accountRepository,
    required this.identityRepository,
    required this.getCurrentUserKeyPair,
  });

  final OutboxDao outboxDao;
  final E2EEEncryptionService e2eeEncryptionService;
  final AccountRepository accountRepository;
  final IdentityRepository identityRepository;
  final Future<CryptoKeyPair?> Function() getCurrentUserKeyPair;

  /// Enqueues a 'claim' event for a new voucher.
  Future<void> dispatchVoucherClaim(Voucher voucher) async {
    await _enqueueMutation(
      voucher: voucher,
      eventType: 'claim',
      payload: {
        'voucher_id': voucher.id.value,
        'type': voucher.type.name,
        'amount_minor': voucher.amount.minorUnits,
        'currency_code': voucher.currency.code,
        'date': voucher.date.toIso8601String(),
        'description': voucher.description,
        'sender_signature_hex': voucher.senderSignatureHex,
        'sender_public_key_hex': voucher.senderPublicKeyHex,
        'signer_phone': voucher.signerPhone,
        'origin_voucher_id': voucher.originVoucherId?.value,
        'reference_number': voucher.referenceNumber,
      },
    );
  }

  /// Enqueues a 'collateralSync' event for a collateral attached to a voucher.
  Future<void> dispatchCollateralSync(
      Voucher voucher, Collateral collateral) async {
    await _enqueueMutation(
      voucher: voucher,
      eventType: 'collateralSync',
      payload: {
        'voucher_id': voucher.id.value,
        'collateral': {
          'id': collateral.id.value,
          'description': collateral.description,
          'value_minor': collateral.estimatedValue.minorUnits,
          'currency_code': collateral.currency.code,
          'status': collateral.status.name,
          'expiry_date': collateral.expiryDate?.toIso8601String(),
        },
      },
    );
  }

  /// Enqueues an 'acceptance' event (digital signature) for an existing voucher.
  Future<void> dispatchVoucherAcceptance(Voucher voucher) async {
    await _enqueueMutation(
      voucher: voucher,
      eventType: 'acceptance',
      payload: {
        'voucher_id': voucher.id.value,
        'receiver_signature_hex': voucher.receiverSignatureHex,
        'receiver_public_key_hex': voucher.receiverPublicKeyHex,
        'signer_phone': voucher.signerPhone,
      },
    );
  }

  /// Enqueues a 'rejection' event.
  Future<void> dispatchVoucherRejection(Voucher voucher) async {
    await _enqueueMutation(
      voucher: voucher,
      eventType: 'rejection',
      payload: {
        'voucher_id': voucher.id.value,
        'rejection_reason': voucher.rejectionReason,
      },
    );
  }

  /// Enqueues a 'withdrawal' event.
  Future<void> dispatchVoucherWithdrawal(Voucher voucher) async {
    await _enqueueMutation(
      voucher: voucher,
      eventType: 'withdrawal',
      payload: {
        'voucher_id': voucher.id.value,
      },
    );
  }

  /// Enqueues a generic E2EE-encrypted event for a counterparty.
  ///
  /// Protocol §5.A: Ensures encryption for the correct party (Mediator B in tripartite).
  /// If public key is missing, performs active discovery via server lookup.
  Future<Result<void>> dispatchGenericEvent({
    required String counterpartyAccountId,
    required String eventType,
    required Map<String, dynamic> payload,
    String? voucherId,
  }) async {
    try {
      final senderKeyPair = await getCurrentUserKeyPair();
      if (senderKeyPair == null) return const Success(null);

      // 1. Resolve counterparty public key.
      final partyResult = await accountRepository
          .getPartyDetails(AccountId(counterpartyAccountId));
      final party = partyResult.valueOrNull;
      if (party == null) {
        return const FailureResult(ValidationFailure(
            messageAr: AppStringsAr.noCounterpartyDataFound));
      }

      String? receiverPubKey = party.currentPublicKeyHex;

      // §5.B: Active Public Key Discovery
      // If not local, recursively seek via Phone/Email on server.
      if (receiverPubKey == null || receiverPubKey.isEmpty) {
        PublicKeyLookupResult? serverIdentity;
        if (party.phoneNumber != null && party.phoneNumber!.isNotEmpty) {
          serverIdentity =
              await identityRepository.lookupByPhone(phone: party.phoneNumber!);
        } else if (party.email != null && party.email!.isNotEmpty) {
          serverIdentity =
              await identityRepository.lookupByEmail(email: party.email!);
        }

        // §6: Sync Privacy Policy — check if target has restricted access.
        if (serverIdentity != null && serverIdentity.syncBlocked) {
          return const FailureResult(ValidationFailure(
            messageAr: AppStringsAr.theCounterpartyHasRestricted,
          ));
        }

        if (serverIdentity != null) {
          receiverPubKey = serverIdentity.publicKeyHex;
          // Optionally update local cache immediately
          await accountRepository.savePartyDetails(party.copyWith(
            currentPublicKeyHex: receiverPubKey,
            publicKeyHistoryHex: serverIdentity.allAuthorizedKeys,
          ));
        }
      }

      if (receiverPubKey == null || receiverPubKey.isEmpty) {
        // ── Queue Suspension ──────────────────────────────────────────────────
        // If we cannot find a public key, we cannot encrypt.
        // Synchronous flows must stop here to prevent "Plaintext Leakage".
        return const FailureResult(ValidationFailure(
          messageAr:
              AppStringsAr.theCounterpartysPublicKey,
        ));
      }

      // 2. Encrypt Payload strictly for receiver's public key (e.g. Mediator B).
      final encrypted = await e2eeEncryptionService.encryptPayload(
        rawPayload: payload,
        senderKeyPair: senderKeyPair,
        receiverPublicKeyHex: receiverPubKey,
      );

      // 3. Enqueue to Outbox table.
      final enqueueRes = await outboxDao.enqueue(OutboxEntry(
        id: const Uuid().v4(),
        eventType: eventType,
        voucherId: voucherId,
        counterpartyAccountId: counterpartyAccountId,
        encryptedPayload: encrypted,
        state: 'pending',
        retryCount: 0,
        createdAt: DateTime.now(),
      ));

      return enqueueRes;
    } catch (e) {
      // Gracefully handle network or encryption errors.
      // We don't want to throw and break the main local transaction.
      return FailureResult(DatabaseFailure(
        messageAr:
            'فشل المزامنة المحلية: ${TextSanitizer.sanitizeErrorMessage(e)}',
      ));
    }
  }

  /// Internal helper to resolve counterparty identity, encrypt, and enqueue.
  Future<void> _enqueueMutation({
    required Voucher voucher,
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    await dispatchGenericEvent(
      counterpartyAccountId: voucher.counterpartyId.value,
      eventType: eventType,
      payload: payload,
      voucherId: voucher.id.value,
    );
  }
}
