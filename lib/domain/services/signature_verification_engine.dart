import 'dart:typed_data';

import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/services/receipt_signing_service.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/signable_receipt.dart';

/// Result of the cross-vector signature verification process.
final class SignatureVerificationResult {
  const SignatureVerificationResult._({
    required this.status,
    this.matchedKeyHex,
    this.failureReason,
  });

  /// Verification succeeded — signature matches a known key.
  factory SignatureVerificationResult.verified(String matchedKeyHex) =>
      SignatureVerificationResult._(
        status: AgreementStatus.accepted,
        matchedKeyHex: matchedKeyHex,
      );

  /// Verification failed — signature doesn't match any known key.
  factory SignatureVerificationResult.unverified(String reason) =>
      SignatureVerificationResult._(
        status: AgreementStatus.unverified,
        failureReason: reason,
      );

  /// Account not found — unknown sender.
  factory SignatureVerificationResult.accountNotFound() =>
      const SignatureVerificationResult._(
        status: AgreementStatus.unverified,
        failureReason: 'ACCOUNT_NOT_FOUND',
      );

  final AgreementStatus status;
  final String? matchedKeyHex;
  final String? failureReason;

  bool get isVerified => status == AgreementStatus.accepted;
  bool get isAccountNotFound => failureReason == 'ACCOUNT_NOT_FOUND';
}

/// Implements the Cross-Vector Verification protocol (§5 of the
/// Digital Signature Protocol).
///
/// When a voucher arrives (via QR, server, or SMS), this engine:
///  1. Extracts the sender's identity (phone/email).
///  2. Fetches the local array of public keys for that account.
///  3. Attempts validation starting with the "Current" public key.
///  4. Falls back through historical keys if the current key fails.
///  5. Returns a [SignatureVerificationResult] indicating success or failure.
class SignatureVerificationEngine {
  const SignatureVerificationEngine({
    required ReceiptSigningService signingService,
    required AccountRepository accountRepository,
    required IdentityRepository identityRepository,
  })  : _signing = signingService,
        _accounts = accountRepository,
        _identity = identityRepository;

  final ReceiptSigningService _signing;
  final AccountRepository _accounts;
  final IdentityRepository _identity;

  /// Verifies an incoming voucher's signature against the sender's known keys.
  ///
  /// [voucher] — the incoming voucher with its attached signature.
  /// [senderPhone] — phone number extracted from the incoming payload.
  /// [senderEmail] — email extracted from the incoming payload (optional).
  /// [myPhone] — the current user's own phone (used in canonical payload).
  ///
  /// Returns a [SignatureVerificationResult] that determines whether the
  /// voucher is committed as "Accepted" or flagged as "Unapproved/Suspended".
  Future<SignatureVerificationResult> verifyIncomingVoucher({
    required Voucher voucher,
    required String senderPhone,
    String? senderEmail,
    required String myPhone,
  }) async {
    if (voucher.senderSignatureHex == null ||
        voucher.senderPublicKeyHex == null) {
      return SignatureVerificationResult.unverified('NO_SIGNATURE_PRESENT');
    }

    // 1. Identity Extraction — find the local account by phone/email.
    final accountId = await _resolveAccountId(senderPhone, senderEmail);
    if (accountId == null) {
      return SignatureVerificationResult.accountNotFound();
    }

    // 2. Key Retrieval — fetch local public key list.
    final partyResult = await _accounts.getPartyDetails(accountId);
    final party = partyResult.valueOrNull;

    List<String> keysToTry = [];

    // Prefer locally cached keys (offline-first).
    if (party != null && party.hasPublicKey) {
      keysToTry = party.allAuthorizedKeys;
    }

    // If no local keys, attempt server lookup.
    if (keysToTry.isEmpty) {
      final serverResult = await _tryServerLookup(senderPhone);
      if (serverResult != null) {
        keysToTry = serverResult.allAuthorizedKeys;
      }
    }

    if (keysToTry.isEmpty) {
      return SignatureVerificationResult.unverified('NO_KEYS_AVAILABLE');
    }

    // 3+4. Iteration & Matching — try current key first, then historical.
    final signable = SignableReceipt(
      amountMinor: voucher.amount.minorUnits,
      currencyCode: voucher.currency.code,
      senderPhone: senderPhone,
      receiverPhone: myPhone,
      dateIso: voucher.date.toIso8601String().split('T').first,
      receiptUuid: voucher.id.value,
    );

    final payloadHash = _signing.hashPayload(signable.canonicalPayload);
    final signatureBytes = _hexToBytes(voucher.senderSignatureHex!);

    for (final keyHex in keysToTry) {
      try {
        final publicKeyBytes = _hexToBytes(keyHex);
        final isValid = _signing.verifyRaw(
          signatureBytes: signatureBytes,
          payloadHash: payloadHash,
          publicKey: publicKeyBytes,
        );
        if (isValid) {
          // 5. Success State — matched!
          return SignatureVerificationResult.verified(keyHex);
        }
      } catch (_) {
        // Invalid key format — skip and try next.
        continue;
      }
    }

    // 6. Failure State — no key matched.
    return SignatureVerificationResult.unverified('SIGNATURE_MISMATCH');
  }

  /// Attempts to find an account ID by phone first, then by email.
  Future<AccountId?> _resolveAccountId(
    String senderPhone,
    String? senderEmail,
  ) async {
    final phoneResult = await _accounts.findAccountByPhone(senderPhone);
    final phoneId = phoneResult.valueOrNull;
    if (phoneId != null) return phoneId;

    if (senderEmail != null && senderEmail.isNotEmpty) {
      final emailResult = await _accounts.findAccountByEmail(senderEmail);
      final emailId = emailResult.valueOrNull;
      if (emailId != null) return emailId;
    }

    return null;
  }

  /// Attempts a server-side key lookup for the sender.
  Future<PublicKeyLookupResult?> _tryServerLookup(String phone) async {
    try {
      return await _identity.lookupByPhone(phone: phone);
    } catch (_) {
      return null;
    }
  }

  static Uint8List _hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      throw ArgumentError('Odd-length hex string: ${hex.length}');
    }
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
