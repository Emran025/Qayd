import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:qayd/domain/services/crypto_identity_service.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/digital_signature.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';

/// Ed25519 implementation of [CryptoIdentityService] using bip39 & ed25519_edwards.
///
/// - Mnemonic generation uses cryptographically secure randomness.
/// - Key derivation is deterministic: same seed → same key pair.
/// - Signing produces 64-byte Ed25519 signatures.
final class Ed25519IdentityService implements CryptoIdentityService {
  const Ed25519IdentityService();

  @override
  MnemonicPhrase generateMnemonic() {
    // Generate a secure 24-word standard BIP39 mnemonic (256 bits of entropy).
    final phrase = bip39.generateMnemonic(strength: 256);
    return MnemonicPhrase.fromPhrase(phrase);
  }

  @override
  CryptoKeyPair deriveKeyPair(MnemonicPhrase mnemonic) {
    // Derives a 64-byte seed from the mnemonic via PBKDF2-SHA512 (BIP39 standard).
    final fullSeed = bip39.mnemonicToSeed(mnemonic.phrase);

    // Ed25519 only needs 32 bytes for the seed scalar.
    final seed32 = fullSeed.sublist(0, 32);

    // Derive the Ed25519 private key object from the 32 byte seed.
    final privateKey = ed.newKeyFromSeed(seed32);
    // Derive the corresponding public key.
    final publicKey = ed.public(privateKey);

    return CryptoKeyPair(
      privateKey: Uint8List.fromList(privateKey.bytes),
      publicKey: Uint8List.fromList(publicKey.bytes),
    );
  }

  @override
  DigitalSignature sign(Uint8List payloadHash, CryptoKeyPair keyPair) {
    final privateKey = ed.PrivateKey(keyPair.privateKey);
    // Sign the hash with the private key
    final signatureBytes = ed.sign(privateKey, payloadHash);

    return DigitalSignature(
      signatureBytes: Uint8List.fromList(signatureBytes),
      signerPublicKey: keyPair.publicKey,
      payloadHash: payloadHash,
    );
  }

  @override
  bool verify(
    Uint8List signatureBytes,
    Uint8List payloadHash,
    Uint8List publicKeyBytes,
  ) {
    try {
      final publicKey = ed.PublicKey(publicKeyBytes);
      // Verify signature against public key and hash
      return ed.verify(publicKey, payloadHash, signatureBytes);
    } catch (_) {
      return false; // Invalid format or mismatched signature
    }
  }
}
