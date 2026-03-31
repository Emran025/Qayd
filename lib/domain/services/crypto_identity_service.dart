import 'dart:typed_data';

import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/digital_signature.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';

/// Domain contract for cryptographic identity operations.
///
/// Handles mnemonic generation, key derivation, signing, and verification.
/// The domain layer defines the interface; the data layer provides the
/// Ed25519 implementation.
abstract interface class CryptoIdentityService {
  /// Generates a new random 24-word BIP39 mnemonic.
  MnemonicPhrase generateMnemonic();

  /// Deterministically derives an Ed25519 key pair from a mnemonic.
  ///
  /// The same mnemonic always produces the same key pair.
  CryptoKeyPair deriveKeyPair(MnemonicPhrase mnemonic);

  /// Signs a SHA-256 payload hash with the private key.
  DigitalSignature sign(Uint8List payloadHash, CryptoKeyPair keyPair);

  /// Verifies a signature against a public key and payload hash.
  ///
  /// Returns `true` if the signature is mathematically valid.
  bool verify(
    Uint8List signatureBytes,
    Uint8List payloadHash,
    Uint8List publicKey,
  );
}
