import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/digital_signature.dart';
import 'package:qayd/domain/value_objects/signable_receipt.dart';
import 'package:qayd/domain/services/crypto_identity_service.dart';

/// Signs and verifies receipt payloads using Ed25519 digital signatures.
///
/// Uses [CryptoIdentityService] for the actual cryptographic operations.
/// This service handles the receipt-specific canonical payload → hash → sign flow.
class ReceiptSigningService {
  const ReceiptSigningService({required CryptoIdentityService cryptoService})
      : _crypto = cryptoService;

  final CryptoIdentityService _crypto;

  /// Hashes the canonical payload string using SHA-256.
  Uint8List hashPayload(String canonicalPayload) {
    final bytes = utf8.encode(canonicalPayload);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  /// Signs a receipt's canonical payload with the given key pair.
  ///
  /// Returns a [DigitalSignature] containing the signature bytes,
  /// the signer's public key, and the SHA-256 hash of the payload.
  DigitalSignature signReceipt(
    SignableReceipt receipt,
    CryptoKeyPair keyPair,
  ) {
    final payloadHash = hashPayload(receipt.canonicalPayload);
    return _crypto.sign(payloadHash, keyPair);
  }

  /// Signs an arbitrary canonical UTF-8 string (e.g. fiscal snapshot aggregate).
  DigitalSignature signCanonicalString(
    String canonical,
    CryptoKeyPair keyPair,
  ) {
    final payloadHash = hashPayload(canonical);
    return _crypto.sign(payloadHash, keyPair);
  }

  /// Verifies a receipt's signature against the signer's public key.
  ///
  /// Reconstructs the canonical payload hash and checks the signature.
  bool verifyReceiptSignature(
    SignableReceipt receipt,
    DigitalSignature signature,
  ) {
    final payloadHash = hashPayload(receipt.canonicalPayload);
    return _crypto.verify(
      signature.signatureBytes,
      payloadHash,
      signature.signerPublicKey,
    );
  }

  /// Verifies a raw signature against a known public key and payload hash.
  bool verifyRaw({
    required Uint8List signatureBytes,
    required Uint8List payloadHash,
    required Uint8List publicKey,
  }) {
    return _crypto.verify(signatureBytes, payloadHash, publicKey);
  }
}
