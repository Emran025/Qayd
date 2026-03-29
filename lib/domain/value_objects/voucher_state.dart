/// Lifecycle of a financial voucher: draft → confirmed → settled (no backward moves).
enum VoucherState {
  draft,
  confirmed,
  settled;

  bool get isDraft => this == VoucherState.draft;

  bool get isConfirmed => this == VoucherState.confirmed;

  bool get isSettled => this == VoucherState.settled;
}
