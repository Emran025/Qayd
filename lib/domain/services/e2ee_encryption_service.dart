import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/digital_signature.dart';

/// Service responsible for End-to-End Encrypting arbitrary business payloads
/// before they are routed through the Zero-Knowledge backend architecture.
abstract class E2EEEncryptionService {
  /// Encrypts an arbitrary JSON payload using a derived shared secret 
  /// (e.g., via ECDH between [senderKeyPair] and [receiverPublicKeyHex]).
  /// Returns a Base64 encoded ciphertext string.
  Future<String> encryptPayload({
    required Map<String, dynamic> rawPayload,
    required CryptoKeyPair senderKeyPair,
    required String receiverPublicKeyHex,
  });

  /// Decrypts a Base64 ciphertext back into a verified JSON payload.
  /// Uses the receiver's private key and the sender's public key.
  Future<Map<String, dynamic>> decryptPayload({
    required String encryptedPayload,
    required CryptoKeyPair receiverKeyPair,
    required String senderPublicKeyHex,
  });

  /// Verifies the embedded cryptographic signature inside a decrypted payload 
  /// strictly belongs to the defined counterparty.
  bool verifySignerAuthenticity({
    required Map<String, dynamic> decryptedPayload,
    required String senderPublicKeyHex,
    required DigitalSignature signature,
  });
}
