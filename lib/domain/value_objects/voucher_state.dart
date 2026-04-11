/// Lifecycle of a financial voucher: draft → confirmed → settled (no backward moves).
/// Additionally, `withdrawn` is a terminal state for cancelled/retracted vouchers.
enum VoucherState {
  draft,
  confirmed,
  settled,
  withdrawn;

  bool get isDraft => this == VoucherState.draft;

  bool get isConfirmed => this == VoucherState.confirmed;

  bool get isSettled => this == VoucherState.settled;

  bool get isWithdrawn => this == VoucherState.withdrawn;

}
