/// Output DTO returned after successfully creating a dual transfer.
class CreateDualTransferOutput {
  const CreateDualTransferOutput({
    required this.receiptVoucherId,
    required this.paymentVoucherId,
    required this.dualGroupId,
  });

  /// UUID of the receipt voucher (sender → fund).
  final String receiptVoucherId;

  /// UUID of the payment voucher (fund → receiver).
  final String paymentVoucherId;

  /// UUID of the dual transfer group linking both vouchers.
  final String dualGroupId;
}
