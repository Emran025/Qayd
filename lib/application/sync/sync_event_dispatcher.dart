import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/repositories/outbox_dao.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/services/e2ee_encryption_service.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:uuid/uuid.dart';

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
        'signature_hex': voucher.signatureHex,
        'signer_public_key_hex': voucher.signerPublicKeyHex,
        'signer_phone': voucher.signerPhone,
        'origin_voucher_id': voucher.originVoucherId?.value,
        'reference_number': voucher.referenceNumber,
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
        'signature_hex': voucher.signatureHex,
        'signer_public_key_hex': voucher.signerPublicKeyHex,
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

  /// Internal helper to resolve counterparty identity, encrypt, and enqueue.
  Future<void> _enqueueMutation({
    required Voucher voucher,
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    final senderKeyPair = await getCurrentUserKeyPair();
    if (senderKeyPair == null) return;

    // 1. Resolve counterparty public key.
    final partyResult = await accountRepository.getPartyDetails(voucher.counterpartyId);
    final party = partyResult.valueOrNull;
    if (party == null) return;

    String? receiverPubKey = party.currentPublicKeyHex;
    
    // If we don't have it locally, attempt a network lookup (or skip until next sync).
    if (receiverPubKey == null || receiverPubKey.isEmpty) {
      if (party.phoneNumber != null) {
        final serverIdentity = await identityRepository.lookupByPhone(phone: party.phoneNumber!);
        receiverPubKey = serverIdentity?.publicKeyHex;
      } else if (party.email != null) {
        final serverIdentity = await identityRepository.lookupByEmail(email: party.email!);
        receiverPubKey = serverIdentity?.publicKeyHex;
      }
    }

    if (receiverPubKey == null || receiverPubKey.isEmpty) {
      // Cannot E2EE for this counterparty yet - defer until identity discovery handshake occurs.
      return; 
    }

    // 2. Encrypt Payload strictly for receiver's public key.
    final encrypted = await e2eeEncryptionService.encryptPayload(
      rawPayload: payload,
      senderKeyPair: senderKeyPair,
      receiverPublicKeyHex: receiverPubKey,
    );

    // 3. Enqueue to Outbox table.
    await outboxDao.enqueue(OutboxEntry(
      id: const Uuid().v4(),
      eventType: eventType,
      voucherId: voucher.id.value,
      counterpartyAccountId: voucher.counterpartyId.value,
      encryptedPayload: encrypted,
      state: 'pending',
      retryCount: 0,
      createdAt: DateTime.now(),
    ));
  }
}
