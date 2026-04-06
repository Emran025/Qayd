import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/date_range.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

/// Domain-level filter for listing vouchers (no storage details).
final class VoucherQueryFilter {
  const VoucherQueryFilter({
    this.state,
    this.dateRange,
    this.counterpartyId,
    this.affectedAccountId,
    this.involvedAccountId,
    this.type,
    this.excludeTripartite,
    this.onlyTripartite,
  });

  final VoucherState? state;
  final DateRange? dateRange;
  final AccountId? counterpartyId;
  final AccountId? affectedAccountId;

  /// Find vouchers where this account is EITHER the affected OR the counterparty.
  final AccountId? involvedAccountId;

  final VoucherType? type;
  final bool? excludeTripartite;
  final bool? onlyTripartite;

  bool get isEmpty =>
      state == null &&
      dateRange == null &&
      counterpartyId == null &&
      affectedAccountId == null &&
      involvedAccountId == null &&
      type == null &&
      excludeTripartite == null &&
      onlyTripartite == null;
}
