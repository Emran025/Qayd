/// Output from a successful tripartite intermediary transfer creation.
class CreateTripartiteTransferOutput {
  const CreateTripartiteTransferOutput({
    required this.receiptVoucherId,
    required this.paymentVoucherId,
    required this.transferGroupId,
  });

  /// ID of the receipt voucher (A → C).
  final String receiptVoucherId;

  /// ID of the payment voucher (C → B) — initially contingent.
  final String paymentVoucherId;

  /// Shared UUID linking both vouchers.
  final String transferGroupId;
}
