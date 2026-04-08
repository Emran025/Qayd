import 'dart:convert';
import 'dart:typed_data';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/core/result/result.dart';
import 'package:flutter/foundation.dart';
import 'package:qayd/domain/entities/sync_node.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/services/e2ee_encryption_service.dart';
import 'package:qayd/domain/services/receipt_signing_service.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/signable_receipt.dart';
import 'package:qayd/domain/repositories/attachment_repository.dart';
import 'package:qayd/domain/repositories/collateral_repository.dart';
import 'package:qayd/data/encryption/voucher_key_service.dart';
import 'package:qayd/domain/entities/voucher_attachment.dart';
import 'package:qayd/domain/value_objects/attachment_id.dart';
import 'package:qayd/domain/value_objects/attachment_source_type.dart';
import 'package:qayd/domain/entities/collateral.dart';
import 'package:qayd/domain/value_objects/collateral_id.dart';
import 'package:qayd/domain/value_objects/collateral_status.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/entities/collateral_revaluation.dart';
import 'package:qayd/domain/value_objects/tripartite_meta.dart';
import 'package:qayd/domain/value_objects/tripartite_role.dart';
import 'package:uuid/uuid.dart';

/// Intercepts inbound [SyncNode] streams, enforces E2EE Cryptographic rules,
/// decrypts the payloads, and mutates the local Drift databases securely.
class SyncPayloadProcessor {
  SyncPayloadProcessor({
    required this.identityRepository,
    required this.voucherRepository,
    required this.ledgerRepository,
    required this.accountRepository,
    required this.currencyRepository,
    required this.e2eeService,
    required this.signingService,
    required this.getCurrentUserKeyPair,
    required this.attachmentRepository,
    required this.collateralRepository,
    required this.voucherKeyService,
    required this.notificationMessageRepository,
    this.onDecryptionFailure,
  });

  final IdentityRepository identityRepository;
  final VoucherRepository voucherRepository;
  final LedgerRepository ledgerRepository;
  final AccountRepository accountRepository;
  final CurrencyRepository currencyRepository;
  final NotificationMessageRepository notificationMessageRepository;
  final E2EEEncryptionService e2eeService;
  final ReceiptSigningService signingService;
  final Future<CryptoKeyPair> Function() getCurrentUserKeyPair;
  final AttachmentRepository attachmentRepository;
  final CollateralRepository collateralRepository;
  final VoucherKeyService voucherKeyService;
  final void Function(String nodeId)? onDecryptionFailure;

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
        final senderEmail = partyResult.valueOrNull?.email ?? '';

        PublicKeyLookupResult? counterpartIdentityResult;

        if (senderPhone.isNotEmpty) {
          counterpartIdentityResult = await identityRepository.lookupByPhone(
            phone: senderPhone,
          );
        }

        if (counterpartIdentityResult == null && senderEmail.isNotEmpty) {
          counterpartIdentityResult = await identityRepository.lookupByEmail(
            email: senderEmail,
          );
        }

        if (counterpartIdentityResult == null) {
          debugPrint(
            'Blocked SyncNode [${node.id}]: Untrusted or Unknown Sender Identity.',
          );
          continue; // DROP SILENTLY
        }

        final counterpartPublicKey = counterpartIdentityResult.publicKeyHex;

        // 2. Decrypt Payload Enclave
        late final Map<String, dynamic> decryptedRawPayload;
        try {
          decryptedRawPayload = await e2eeService.decryptPayload(
            encryptedPayload: node.encryptedPayload,
            receiverKeyPair: myKeyPair,
            senderPublicKeyHex: counterpartPublicKey,
          );
        } catch (e) {
          debugPrint('Decryption failed for SyncNode [${node.id}]: $e');
          onDecryptionFailure?.call(node.id);
          continue; // Skip this node
        }

        // 3. Process Domain Actions Structurally with Signatures
        switch (node.eventType) {
          case SyncEventType.claim:
            await _inboundVoucherClaim(decryptedRawPayload, node.id, node.senderId.toString());
            break;
          case SyncEventType.acceptance:
            await _inboundVoucherAcceptance(
              decryptedRawPayload,
              counterpartPublicKey,
              senderPhone,
              senderEmail,
              node.id,
              node.senderId.toString(),
            );
            break;
          case SyncEventType.rejection:
            await _inboundVoucherRejection(decryptedRawPayload, node.id, node.senderId.toString());
            break;
          case SyncEventType.journalEntry:
            await _inboundJournalEntryMirrored(decryptedRawPayload);
            break;
          case SyncEventType.attachmentSync:
            await _inboundAttachmentSync(decryptedRawPayload);
            break;
          case SyncEventType.collateralSync:
            await _inboundCollateralSync(decryptedRawPayload);
            break;
          case SyncEventType.collateralUpdate:
            await _inboundCollateralRevaluation(decryptedRawPayload);
            break;
          case SyncEventType.withdrawal:
            await _inboundVoucherWithdrawal(decryptedRawPayload, node.id, node.senderId.toString());
            break;
          case SyncEventType.settlement:
            await _inboundVoucherSettlement(decryptedRawPayload, node.id, node.senderId.toString());
            break;
          case SyncEventType.p2pHandshake:
            // P2P handshake is handled at the transport layer, not here.
            debugPrint(
              'P2P Handshake event received — delegating to P2P service.',
            );
            break;
          case SyncEventType.tripartiteRequest:
            await _inboundTripartiteRequest(decryptedRawPayload, node.senderId.toString(), node.id);
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

  Future<void> _inboundVoucherClaim(
    Map<String, dynamic> payload,
    String nodeId,
    String senderId,
  ) async {
    // Protocol §5 — Inbound Voucher Claim Processing.
    final String? voucherIdStr = payload['voucher_id'] as String?;
    if (voucherIdStr == null) return;

    // 1. Idempotency Guard
    final existingResult = await voucherRepository.getById(VoucherId(voucherIdStr));
    if (existingResult.isSuccess && existingResult.valueOrNull != null) return;

    // 2. Flip Logic: From their perspective to ours.
    final typeStr = payload['type'] as String? ?? 'receipt';
    // If they sent a Receipt (they got money), for us it is a Payment (we gave money).
    final myType = typeStr == 'receipt' ? VoucherType.payment : VoucherType.receipt;

    final amountMinor = payload['amount_minor'] as int? ?? 0;
    final currencyCode = payload['currency_code'] as String? ?? 'YER';
    final date = DateTime.tryParse(payload['date'] as String? ?? '') ?? DateTime.now();

    // 3. Counterparty mapping: The one who sent the sync node is our counterparty.
    // (Sender ID is handled in the caller processIncomingNodes, but we need the AccountId here)
    // For now, we rely on the payload's counterparty mapping if available, 
    // but better to resolve from the Node's sender.
    // In our system, the sender of the claim IS the counterparty.
    final senderParty = await accountRepository.findAccountByPhone(payload['signer_phone'] ?? '');
    final counterpartyId = senderParty.valueOrNull ?? AccountId(payload['counterparty_id'] ?? '');

    // 4. Affected Account mapping: For inbound claims, our default fund is usually affected.
    final allAccounts = await accountRepository.getAll();
    final myFund = allAccounts.valueOrNull?.firstWhere(
      (a) => a.classification.standardKind?.name == 'liquidAssets',
      orElse: () => allAccounts.valueOrNull!.first,
    );
    final affectedAccountId = myFund?.id ?? AccountId('default-fund');

    // 5. Currency Lookup
    final currencyResult = await currencyRepository.getByCode(currencyCode);
    final currency = currencyResult.valueOrNull!;

    // 6. Entity Reconstruction
    final tripartiteData = payload['tripartite_meta'] as Map<String, dynamic>?;
    TripartiteMeta? tripartiteMeta;
    if (tripartiteData != null) {
      tripartiteMeta = TripartiteMeta(
        transferGroupId: tripartiteData['transfer_group_id'] as String? ?? '',
        role: TripartiteRole.fromColumnValue(tripartiteData['role'] as String?) ?? TripartiteRole.intermediaryReceipt,
        linkedPartyId: AccountId(tripartiteData['linked_party_id'] as String? ?? ''),
        mediatorAccountId: tripartiteData['mediator_account_id'] != null ? AccountId(tripartiteData['mediator_account_id'] as String) : null,
        isContingent: tripartiteData['is_contingent'] as bool? ?? false,
      );
    }

    final voucher = Voucher.restore(
      id: VoucherId(voucherIdStr),
      type: myType,
      date: date,
      amount: Money.positiveAmount(amountMinor, currency),
      currency: currency,
      counterpartyId: counterpartyId,
      affectedAccountId: affectedAccountId,
      state: VoucherState.draft, // Inbound claims are always drafts until WE accept them.
      createdAt: DateTime.now(),
      description: payload['description'],
      referenceNumber: payload['reference_number'],
      senderStatus: AgreementStatus.accepted, // They signed it.
      receiverStatus: AgreementStatus.underRequest, // We haven't.
      senderSignatureHex: payload['sender_signature_hex'],
      senderPublicKeyHex: payload['sender_public_key_hex'],
      signerPhone: payload['signer_phone'],
      originVoucherId: payload['origin_voucher_id'] != null ? VoucherId(payload['origin_voucher_id']) : null,
      tripartiteMeta: tripartiteMeta,
    );

    // 7. Persist
    await voucherRepository.save(voucher);
    debugPrint('VoucherClaim [$voucherIdStr]: Ingested and stored as $myType.');

    // 8. Reciprocal Matching (Conflict Detection)
    // We always create a notification for a new claim, but customize it if it's a conflict.
    final reciprocalResult = await voucherRepository.findReciprocalMatch(
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      counterpartyAccountId: counterpartyId.value,
      type: myType.name,
      referenceDate: date,
    );

    String bodyText = 'سند جديد بقيمة ${amountMinor / 100} $currencyCode';
    String channel = 'voucher_event';

    if (reciprocalResult.isSuccess && reciprocalResult.valueOrNull != null) {
      final localMatch = reciprocalResult.valueOrNull!;
      bodyText = 'سند مطابق — هل ترغب في دمج هذا السند مع المسودة المحلية؟';
      channel = 'conflict';
      
      // We still use voucher_event as base but keep the conflict logic
      await notificationMessageRepository.insert(
        id: nodeId, // Use the sync node ID to prevent duplicates
        bodyText: bodyText,
        counterpartyAccountId: counterpartyId.value,
        createdAtIso: DateTime.now().toIso8601String(),
        channel: channel,
        rawPayloadJson: json.encode({
          'event_type': 'claim',
          'voucher_id': voucherIdStr,
          'local_voucher_id': localMatch.id.value,
          'inbound_payload': payload,
          'has_tripartite_meta': tripartiteMeta != null,
        }),
      );
    } else {
      await notificationMessageRepository.insert(
        id: nodeId,
        bodyText: bodyText,
        counterpartyAccountId: counterpartyId.value,
        createdAtIso: DateTime.now().toIso8601String(),
        channel: channel,
        rawPayloadJson: json.encode({
          'event_type': 'claim',
          'voucher_id': voucherIdStr,
          'inbound_payload': payload,
          'has_tripartite_meta': tripartiteMeta != null,
        }),
      );
    }
  }

  Future<void> _inboundVoucherAcceptance(
    Map<String, dynamic> payload,
    String senderPublicKey,
    String senderPhone,
    String senderEmail,
    String nodeId,
    String senderId,
  ) async {
    final String voucherIdStr = payload['voucher_id'];
    final String receiverSignatureHex = payload['receiver_signature_hex'];

    final voucherResult = await voucherRepository.getById(
      VoucherId(voucherIdStr),
    );
    if (voucherResult.isFailure || voucherResult.valueOrNull == null) return;
    final draft = voucherResult.valueOrNull!;

    // Resolve current user's phone for canonical payload construction.
    final myPartyResult = await accountRepository.getPartyDetails(
      draft.affectedAccountId,
    );
    final myPhone = myPartyResult.valueOrNull?.phoneNumber ?? '';

    // Build canonical payload for signature verification.
    final signable = SignableReceipt(
      amountMinor: draft.amount.minorUnits,
      currencyCode: draft.currency.code,
      senderPhone: myPhone,
      receiverPhone: senderPhone,
      dateIso: draft.date.toIso8601String().split('T').first,
      receiptUuid: draft.id.value,
    );

    final payloadHash = signingService.hashPayload(signable.canonicalPayload);
    final Uint8List signatureBytes = _hexToBytes(receiverSignatureHex);

    // ── Protocol §5: Cross-Vector Key-List Verification ──────────────────
    // Build the full list of keys to try: claimed key first, then
    // any known historical keys for this sender.
    final keysToTry = <String>[senderPublicKey];

    // Fetch local party details for the sender to get historical keys.
    var senderAccountResult = await accountRepository.findAccountByPhone(
      senderPhone,
    );
    if (senderAccountResult.valueOrNull == null && senderEmail.isNotEmpty) {
      senderAccountResult = await accountRepository.findAccountByEmail(
        senderEmail,
      );
    }

    final senderAccountId = senderAccountResult.valueOrNull;
    if (senderAccountId != null) {
      final senderParty = await accountRepository.getPartyDetails(
        senderAccountId,
      );
      final party = senderParty.valueOrNull;
      if (party != null) {
        for (final histKey in party.allAuthorizedKeys) {
          if (!keysToTry.contains(histKey)) {
            keysToTry.add(histKey);
          }
        }
      }
    }

    // If no local keys beyond the claimed one, try server lookup.
    if (keysToTry.length == 1) {
      PublicKeyLookupResult? serverResult;
      if (senderPhone.isNotEmpty) {
        serverResult = await identityRepository.lookupByPhone(
          phone: senderPhone,
        );
      }
      if (serverResult == null && senderEmail.isNotEmpty) {
        serverResult = await identityRepository.lookupByEmail(
          email: senderEmail,
        );
      }
      if (serverResult != null) {
        for (final key in serverResult.allAuthorizedKeys) {
          if (!keysToTry.contains(key)) {
            keysToTry.add(key);
          }
        }
      }
    }

    // Iterate through all known keys (current + historical).
    bool verified = false;
    String? matchedKey;
    for (final keyHex in keysToTry) {
      try {
        final pubKeyBytes = _hexToBytes(keyHex);
        final isValid = signingService.verifyRaw(
          signatureBytes: signatureBytes,
          payloadHash: payloadHash,
          publicKey: pubKeyBytes,
        );
        if (isValid) {
          verified = true;
          matchedKey = keyHex;
          break;
        }
      } catch (_) {
        // Invalid key format — skip.
        continue;
      }
    }

    if (verified) {
      // §5.5 Success: Mutual digital signature achieved.
      final signedVoucher = draft.attachSignature(
        signatureHex: receiverSignatureHex,
        publicKeyHex: matchedKey!,
        isSender: false, // The counterparty (receiver) signed.
        status: AgreementStatus.accepted,
        signerPhone: senderPhone,
      );
      await voucherRepository.save(signedVoucher);
      debugPrint(
        'Voucher [$voucherIdStr] accepted — verified with key ${matchedKey.substring(0, 8)}…',
      );

      // Create notification for acceptance
      await notificationMessageRepository.insert(
        id: nodeId,
        bodyText: 'تم اعتماد السند من قبل الطرف الآخر',
        counterpartyAccountId: senderId,
        createdAtIso: DateTime.now().toIso8601String(),
        channel: 'voucher_event',
        rawPayloadJson: json.encode({
          'event_type': 'acceptance',
          'voucher_id': voucherIdStr,
        }),
      );
    } else {
      // §5.6 Failure: Suspended as unapproved claim.
      final suspendedVoucher = draft.attachSignature(
        signatureHex: receiverSignatureHex,
        publicKeyHex: senderPublicKey,
        isSender: false, // The counterparty (receiver) signed poorly.
        status: AgreementStatus.unverified,
        signerPhone: senderPhone,
      );
      await voucherRepository.save(suspendedVoucher);
      debugPrint(
        'SECURITY: Voucher [$voucherIdStr] SUSPENDED — '
        'signature mismatch across ${keysToTry.length} key(s).',
      );
    }
  }

  Future<void> _inboundVoucherRejection(
    Map<String, dynamic> payload,
    String nodeId,
    String senderId,
  ) async {
    final String voucherIdStr = payload['voucher_id'];
    final voucherResult = await voucherRepository.getById(
      VoucherId(voucherIdStr),
    );
    if (voucherResult.isFailure || voucherResult.valueOrNull == null) return;

    final rejectedVoucher = voucherResult.valueOrNull!.attachRejection(
      reason: payload['rejection_reason'] as String? ?? '',
      status: AgreementStatus.rejected,
    );
    await voucherRepository.save(rejectedVoucher);

    // Create notification for rejection
    await notificationMessageRepository.insert(
      id: nodeId,
      bodyText: 'تم رفض السند: ${payload['rejection_reason'] ?? ''}',
      counterpartyAccountId: senderId,
      createdAtIso: DateTime.now().toIso8601String(),
      channel: 'voucher_event',
      rawPayloadJson: json.encode({
        'event_type': 'rejection',
        'voucher_id': voucherIdStr,
        'reason': payload['rejection_reason'],
      }),
    );
  }

  Future<void> _inboundJournalEntryMirrored(
    Map<String, dynamic> payload,
  ) async {
    // Secure generation of isolated dual-entry mirror ...
  }

  Future<void> _inboundAttachmentSync(Map<String, dynamic> payload) async {
    final voucherIdStr = payload['voucher_id'] as String?;
    if (voucherIdStr == null) {
      debugPrint('AttachmentSync: missing voucher_id');
      return;
    }

    final attachments = payload['attachments'] as List<dynamic>? ?? [];
    debugPrint(
      'AttachmentSync: received ${attachments.length} attachment(s) for voucher $voucherIdStr',
    );

    final voucherId = VoucherId(voucherIdStr);

    final mappedAttachments = attachments.map((dynamic a) {
      final map = a as Map<String, dynamic>;
      return VoucherAttachment(
        id: AttachmentId(map['id'] as String? ?? const Uuid().v4()),
        voucherId: voucherId,
        fileName: map['file_name'] as String? ?? 'attachment.jpg',
        storagePath: '', // Will be updated after blob download
        encryptedBlobHash: map['blob_hash'] as String? ?? '',
        mimeType: map['mime_type'] as String? ?? 'image/jpeg',
        byteSize: map['byte_size'] as int? ?? 0,
        sourceType: AttachmentSourceType.gallery,
        createdAt: DateTime.now(),
      );
    }).toList();

    if (mappedAttachments.isNotEmpty) {
      await attachmentRepository.saveAll(mappedAttachments);
    }

    // Blob downloading would happen here via a background queue.
  }

  Future<void> _inboundCollateralSync(Map<String, dynamic> payload) async {
    final voucherIdStr = payload['voucher_id'] as String?;
    final collateralData = payload['collateral'] as Map<String, dynamic>?;
    if (voucherIdStr == null || collateralData == null) {
      debugPrint('CollateralSync: missing voucher_id or collateral data');
      return;
    }
    debugPrint('CollateralSync: received collateral for voucher $voucherIdStr');

    final collateralIdStr =
        collateralData['id'] as String? ?? const Uuid().v4();
    final valueMinor = collateralData['value_minor'] as int? ?? 0;
    final currencyCode = collateralData['currency_code'] as String? ?? 'USD';
    final statusStr = collateralData['status'] as String? ?? 'active';
    final expiryIso = collateralData['expiry_date'] as String?;
    // Note: description normally comes decrypted here from processing pipeline
    final description =
        collateralData['description'] as String? ?? 'Collateral item';

    final currencyObj = CurrencyCode(
      code: currencyCode,
      nameAr: currencyCode,
      symbol: currencyCode,
      fractionalDigits: 2,
    );

    final collateral = Collateral(
      id: CollateralId(collateralIdStr),
      voucherId: VoucherId(voucherIdStr),
      description: description,
      estimatedValue: valueMinor > 0
          ? Money.positiveAmount(valueMinor, currencyObj)
          : Money.zero(currencyObj),
      currency: currencyObj,
      status: CollateralStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => CollateralStatus.active,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expiryDate: expiryIso != null ? DateTime.tryParse(expiryIso) : null,
    );

    // Get existing to determine insert vs update
    final existing = await collateralRepository.getById(collateral.id);
    if (existing.isSuccess) {
      await collateralRepository.update(collateral);
    } else {
      await collateralRepository.save(collateral);
    }
  }

  Future<void> _inboundCollateralRevaluation(
    Map<String, dynamic> payload,
  ) async {
    final collateralIdStr = payload['collateral_id'] as String?;
    if (collateralIdStr == null) {
      debugPrint('CollateralRevaluation: missing collateral_id');
      return;
    }
    debugPrint(
      'CollateralRevaluation: received update for collateral $collateralIdStr',
    );

    final collateralId = CollateralId(collateralIdStr);
    final existingR = await collateralRepository.getById(collateralId);
    if (existingR.isFailure) return;

    final existing = existingR.valueOrNull!;

    final newMinor = payload['new_value_minor'] as int?;
    final newExpiryStr = payload['new_expiry'] as String?;
    final reason = payload['reason'] as String? ?? 'Remote update';

    final revalAudit = CollateralRevaluation(
      id: const Uuid().v4(),
      collateralId: collateralId,
      oldValueMinor: existing.estimatedValue.minorUnits,
      newValueMinor: newMinor ?? existing.estimatedValue.minorUnits,
      oldExpiryDate: existing.expiryDate,
      newExpiryDate: newExpiryStr != null
          ? DateTime.tryParse(newExpiryStr)
          : existing.expiryDate,
      reason: reason,
      evaluatedAt: DateTime.now(),
    );

    final updated = existing.revaluate(
      newValue: newMinor != null
          ? (newMinor > 0
                ? Money.positiveAmount(newMinor, existing.currency)
                : Money.zero(existing.currency))
          : null,
      newExpiryDate: newExpiryStr != null
          ? DateTime.tryParse(newExpiryStr)
          : null,
    );

    await collateralRepository.update(updated);
    await collateralRepository.saveRevaluation(revalAudit);
  }

  // ── Threaded Financial Interactions handlers ──────────────────────────

  Future<void> _inboundVoucherWithdrawal(
    Map<String, dynamic> payload,
    String nodeId,
    String senderId,
  ) async {
    final String? voucherIdStr = payload['voucher_id'] as String?;
    if (voucherIdStr == null) {
      debugPrint('VoucherWithdrawal: missing voucher_id');
      return;
    }

    final voucherResult = await voucherRepository.getById(
      VoucherId(voucherIdStr),
    );
    if (voucherResult.isFailure || voucherResult.valueOrNull == null) {
      debugPrint(
        'VoucherWithdrawal [$voucherIdStr]: voucher not found locally.',
      );
      return;
    }

    final voucher = voucherResult.valueOrNull!;
    if (voucher.state.isDraft) {
      // Withdraw the local copy
      final withdrawn = voucher.withdraw(DateTime.now());
      await voucherRepository.save(withdrawn);
      debugPrint('VoucherWithdrawal [$voucherIdStr]: local copy withdrawn.');

      // Create notification for withdrawal
      await notificationMessageRepository.insert(
        id: nodeId,
        bodyText: 'تم سحب السند من قبل صاحب السند',
        counterpartyAccountId: senderId,
        createdAtIso: DateTime.now().toIso8601String(),
        channel: 'voucher_event',
        rawPayloadJson: json.encode({
          'event_type': 'withdrawal',
          'voucher_id': voucherIdStr,
        }),
      );
    } else {
      debugPrint(
        'VoucherWithdrawal [$voucherIdStr]: cannot withdraw — '
        'current state is ${voucher.state.name}.',
      );
    }
  }

  Future<void> _inboundVoucherSettlement(
    Map<String, dynamic> payload,
    String nodeId,
    String senderId,
  ) async {
    final String? voucherIdStr = payload['voucher_id'] as String?;
    if (voucherIdStr == null) {
      debugPrint('VoucherSettlement: missing voucher_id');
      return;
    }

    final voucherResult = await voucherRepository.getById(
      VoucherId(voucherIdStr),
    );
    if (voucherResult.isFailure || voucherResult.valueOrNull == null) {
      debugPrint(
        'VoucherSettlement [$voucherIdStr]: voucher not found locally.',
      );
      return;
    }

    final voucher = voucherResult.valueOrNull!;
    if (voucher.state.isConfirmed) {
      final settled = voucher.settle(DateTime.now());
      await voucherRepository.save(settled);
      debugPrint('VoucherSettlement [$voucherIdStr]: marked as settled.');

      // Create notification for settlement
      await notificationMessageRepository.insert(
        id: nodeId,
        bodyText: 'تم سداد السند بالكامل',
        counterpartyAccountId: senderId,
        createdAtIso: DateTime.now().toIso8601String(),
        channel: 'voucher_event',
        rawPayloadJson: json.encode({
          'event_type': 'settlement',
          'voucher_id': voucherIdStr,
        }),
      );
    } else {
      debugPrint(
        'VoucherSettlement [$voucherIdStr]: cannot settle — '
        'current state is ${voucher.state.name}.',
      );
    }
  }

  Future<void> _inboundTripartiteRequest(
    Map<String, dynamic> payload,
    String senderId,
    String nodeId,
  ) async {
    // Protocol §5 — Inbound Tripartite Request from Sender (A).
    // The mediator (B) saves this as a notification to allow deep-linking to the creation page.
    final now = DateTime.now();
    
    // Resolve sender name for the notification UI
    final accountResult = await accountRepository.getById(AccountId(senderId));
    final senderName = accountResult.valueOrNull?.name ?? 'المُرسل';

    await notificationMessageRepository.insert(
      id: nodeId, // Consistent use of sync node ID
      counterpartyAccountId: senderId,
      bodyText: 'طلب حوالة جديدة من $senderName',
      channel: 'tripartite_event',
      createdAtIso: now.toIso8601String(),
      rawPayloadJson: jsonEncode(payload),
    );
    
    debugPrint('TripartiteRequest [$senderName -> B]: Ingested and stored.');
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
