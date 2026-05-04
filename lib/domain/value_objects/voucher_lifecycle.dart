import 'package:qayd/presentation/l10n/app_strings.dart';
/// Represents the high-level lifecycle of a financial voucher.
///
/// This status is derived from the internal state and the dual-party agreement statuses.
enum VoucherLifecycle {
  /// (مسودة) - Created locally, not yet shared or confirmed.
  draft,

  /// (بانتظار الطرف الآخر) - Signed by the creator and waiting for the counterparty's signature.
  pending,

  /// (مرفوض) - Explicitly rejected by the counterparty.
  rejected,

  /// (مسحوب) - Retracted by the creator before completion.
  withdrawn,

  /// (مكتمل) - Signed by both parties and confirmed in the ledger.
  confirmed,

  /// (تمت التسوية) - Payment has been cleared/settled.
  settled;

  bool get isDraft => this == VoucherLifecycle.draft;
  bool get isPending => this == VoucherLifecycle.pending;
  bool get isRejected => this == VoucherLifecycle.rejected;
  bool get isWithdrawn => this == VoucherLifecycle.withdrawn;
  bool get isConfirmed => this == VoucherLifecycle.confirmed;
  bool get isSettled => this == VoucherLifecycle.settled;

  /// Human readable label in Arabic.
  String get labelAr => switch (this) {
        VoucherLifecycle.draft => AppStrings.draft,
        VoucherLifecycle.pending => AppStrings.waitingForTheOther,
        VoucherLifecycle.rejected => AppStrings.unacceptable,
        VoucherLifecycle.withdrawn => AppStrings.drawn,
        VoucherLifecycle.confirmed => AppStrings.complete,
        VoucherLifecycle.settled => AppStrings.settled,
      };
}
