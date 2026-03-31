import 'package:qayd/domain/value_objects/signable_receipt.dart';
import 'package:qayd/domain/value_objects/signature_status.dart';

/// Represents a receipt received via SMS or QR code for reconciliation.
class IncomingReceipt {
  const IncomingReceipt({
    required this.receipt,
    required this.signatureHex,
    required this.signerPublicKeyHex,
    required this.signatureStatus,
  });

  /// The parsed receipt payload data.
  final SignableReceipt receipt;

  /// The cryptographic signature (if present).
  final String? signatureHex;

  /// The public key of the signer.
  final String? signerPublicKeyHex;

  /// The initial status of the signature (unsigned/signed).
  final SignatureStatus signatureStatus;
}

abstract interface class SmsReceiptListener {
  /// Starts listening for incoming SMS messages that match the Qayd
  /// receipt format. Yields [IncomingReceipt] objects for reconciliation.
  Stream<IncomingReceipt> listenForReceipts();

  /// Attempts to parse a raw SMS body string into an [IncomingReceipt].
  /// Returns null if the format doesn't match.
  IncomingReceipt? parseSmsBody(String body);
}
