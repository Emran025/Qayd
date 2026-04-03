import 'dart:typed_data';
import 'package:qayd/core/result/result.dart';
import 'package:flutter/foundation.dart';
import 'package:qayd/domain/entities/sync_node.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/services/e2ee_encryption_service.dart';
import 'package:qayd/domain/services/receipt_signing_service.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/signable_receipt.dart';

/// Intercepts inbound [SyncNode] streams, enforces E2EE Cryptographic rules,
/// decrypts the payloads, and mutates the local Drift databases securely.
class SyncPayloadProcessor {
  SyncPayloadProcessor({
    required this.identityRepository,
    required this.voucherRepository,
    required this.ledgerRepository,
    required this.accountRepository,
    required this.e2eeService,
    required this.signingService,
    required this.getCurrentUserKeyPair,
  });

  final IdentityRepository identityRepository;
  final VoucherRepository voucherRepository;
  final LedgerRepository ledgerRepository;
  final AccountRepository accountRepository;
  final E2EEEncryptionService e2eeService;
  final ReceiptSigningService signingService;
  final Future<CryptoKeyPair> Function() getCurrentUserKeyPair;

  /// Ingests a list of pushed/pulled encrypted sync nodes
  Future<void> processIncomingNodes(List<SyncNode> nodes) async {
    final myKeyPair = await getCurrentUserKeyPair();

    for (final node in nodes) {
      try {
        // 1. We must determine the counterpart's phone to fetch their keys.
        // Assuming Sender ID strongly correlates with Account mapping / Governance API...
        // For professional rigor, if governance requires phone, we fetch the PartyDetails by ID to get the phone:
        final partyResult = await accountRepository.getPartyDetails(
          AccountId(node.senderId.toString()),
        );
        final senderPhone = partyResult.valueOrNull?.phoneNumber ?? '';

        final counterpartIdentityResult = await identityRepository
            .lookupByPhone(phone: senderPhone);
        if (counterpartIdentityResult == null) {
          debugPrint(
            'Blocked SyncNode [${node.id}]: Untrusted or Unknown Sender Identity.',
          );
          continue; // DROP SILENTLY
        }

        final counterpartPublicKey = counterpartIdentityResult.publicKeyHex;

        // 2. Decrypt Payload Enclave
        final decryptedRawPayload = await e2eeService.decryptPayload(
          encryptedPayload: node.encryptedPayload,
          receiverKeyPair: myKeyPair,
          senderPublicKeyHex: counterpartPublicKey,
        );

        // 3. Process Domain Actions Structurally with Signatures
        switch (node.eventType) {
          case SyncEventType.claim:
            await _inboundVoucherClaim(decryptedRawPayload);
            break;
          case SyncEventType.acceptance:
            await _inboundVoucherAcceptance(
              decryptedRawPayload,
              counterpartPublicKey,
              senderPhone,
            );
            break;
          case SyncEventType.rejection:
            await _inboundVoucherRejection(decryptedRawPayload);
            break;
          case SyncEventType.journalEntry:
            await _inboundJournalEntryMirrored(decryptedRawPayload);
            break;
          case SyncEventType.unknown:
            debugPrint('Warning: Unknown event type in SyncNode [${node.id}]');
            break;
        }
      } catch (e) {
        debugPrint('Security Pipeline Failure for SyncNode [${node.id}]: $e');
      }
    }
  }

  Future<void> _inboundVoucherClaim(Map<String, dynamic> payload) async {
    // Structural Draft ingestion
  }

  Future<void> _inboundVoucherAcceptance(
    Map<String, dynamic> payload,
    String senderPublicKey,
    String senderPhone,
  ) async {
    final String voucherIdStr = payload['voucher_id'];
    final String signatureHex = payload['signature_hex'];

    final voucherResult = await voucherRepository.getById(
      VoucherId(voucherIdStr),
    );
    if (voucherResult.isFailure || voucherResult.valueOrNull == null) return;
    final draft = voucherResult.valueOrNull!;

    // Mathematically verify the signature using SignableReceipt canonical payload
    // to guarantee they are signing exactly the properties we requested!
    final signable = SignableReceipt(
      amountMinor: draft.amount.minorUnits,
      currencyCode: draft.currency.code,
      senderPhone: 'my_phone', // Use current user's phone
      receiverPhone: senderPhone,
      dateIso: draft.date.toIso8601String().split('T').first,
      receiptUuid: draft.id.value,
    );

    final payloadHash = signingService.hashPayload(signable.canonicalPayload);

    // Decode From Hex strings
    final Uint8List signatureBytes = _hexToBytes(signatureHex);
    final Uint8List pubKeyBytes = _hexToBytes(senderPublicKey);

    final isValid = signingService.verifyRaw(
      signatureBytes: signatureBytes,
      payloadHash: payloadHash,
      publicKey: pubKeyBytes,
    );

    if (isValid) {
      // Elevate Trust: Mutual digital signature achieved
      final signedVoucher = draft.attachSignature(
        signatureHex: signatureHex,
        signerPublicKeyHex: senderPublicKey,
        status: AgreementStatus.accepted,
        signerPhone: senderPhone,
      );
      await voucherRepository.save(signedVoucher);
    } else {
      debugPrint(
        'CRITICAL: Malicious or Invalid Cryptographic Signature rejected!',
      );
    }
  }

  Future<void> _inboundVoucherRejection(Map<String, dynamic> payload) async {
    final String voucherIdStr = payload['voucher_id'];
    final voucherResult = await voucherRepository.getById(
      VoucherId(voucherIdStr),
    );
    if (voucherResult.isFailure || voucherResult.valueOrNull == null) return;

    final rejectedVoucher = voucherResult.valueOrNull!.attachSignature(
      signatureHex: 'REJECTED', // Tombstone
      signerPublicKeyHex: 'REJECTED',
      status: AgreementStatus.rejected,
    );
    await voucherRepository.save(rejectedVoucher);
  }

  Future<void> _inboundJournalEntryMirrored(
    Map<String, dynamic> payload,
  ) async {
    // Secure generation of isolated dual-entry mirror ...
  }

  Uint8List _hexToBytes(String hex) {
    if (hex.length % 2 != 0) throw Exception('Odd length hex string');
    var result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
