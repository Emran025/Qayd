import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';

/// Output DTO for the tripartite transfer detail view.
///
/// Aggregates both legs (receipt A→C and payment C→B) into a single
/// unified view that presents the full transfer story to the mediator.
class GetTripartiteDetailOutput {
  const GetTripartiteDetailOutput({
    required this.transferGroupId,
    required this.sourceName,
    required this.destinationName,
    required this.mediatorName,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDigits,
    required this.currencyNameAr,
    required this.dateIso,
    this.description,
    this.receiptVoucher,
    this.paymentVoucher,
    this.senderSignatureHex,
    this.receiverSignatureHex,
    this.senderPublicKeyHex,
    this.receiverPublicKeyHex,
    required this.senderStatusCode,
    required this.receiverStatusCode,
    this.sourceAccountId,
    this.destinationAccountId,
    this.mediatorAccountId,
    this.qrData,
    required this.createdAtIso,
    this.feeAmountMinorUnits,
  });

  /// UUID shared between the receipt and payment vouchers.
  final String transferGroupId;

  /// The original sender (A).
  final String sourceName;

  /// The final receiver (B).
  final String destinationName;

  /// The intermediary (C) — our cashbox.
  final String mediatorName;

  final int amountMinorUnits;
  final String currencyCode;
  final String currencySymbol;
  final int currencyDigits;
  final String currencyNameAr;
  final String dateIso;
  final String? description;

  /// Full details of the receipt leg (A → C).
  final GetVoucherDetailsOutput? receiptVoucher;

  /// Full details of the payment leg (C → B).
  final GetVoucherDetailsOutput? paymentVoucher;

  // Digital signatures of the external parties (A and B).
  final String? senderSignatureHex;
  final String? receiverSignatureHex;
  final String? senderPublicKeyHex;
  final String? receiverPublicKeyHex;

  /// Agreement status of the sender party (A).
  final String senderStatusCode;

  /// Agreement status of the receiver party (B).
  final String receiverStatusCode;

  /// Account IDs for navigation and PDF generation.
  final String? sourceAccountId;
  final String? destinationAccountId;
  final String? mediatorAccountId;

  /// QR data for the tripartite receipt (combines both legs).
  final String? qrData;

  final String createdAtIso;

  /// Fee charged by the mediator (if any), in minor currency units.
  final int? feeAmountMinorUnits;

  /// Convenience getters.
  bool get isFullyAccepted =>
      senderStatusCode == 'accepted' && receiverStatusCode == 'accepted';

  bool get hasBothLegs => receiptVoucher != null && paymentVoucher != null;

  /// Returns true if this represents a True Tripartite Transfer (Bridge/Transfers Account).
  /// Returns false if this is a Dual Transfer (Box/Liquid Assets) since Dual transfers
  /// are real vouchers and have `isContingent = false`.
  bool get isTrueTripartite =>
      (receiptVoucher?.isContingent ?? false) ||
      (paymentVoucher?.isContingent ?? false);
}
