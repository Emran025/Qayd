class ConfirmVoucherOutput {
  const ConfirmVoucherOutput({
    required this.voucherId,
    required this.transactionId,
    required this.debitEntryId,
    required this.creditEntryId,
    required this.stateCode,
  });

  final String voucherId;
  final String transactionId;
  final String debitEntryId;
  final String creditEntryId;
  final String stateCode;
}
