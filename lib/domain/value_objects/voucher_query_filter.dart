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
    this.involvedRootAccountId,
    this.involvedCounterRootAccountId,
    this.isInternalOnly,
    this.type,
    this.excludeTripartite,
    this.onlyTripartite,
    this.costCenterId,
  });

  final VoucherState? state;
  final DateRange? dateRange;
  final AccountId? counterpartyId;
  final AccountId? affectedAccountId;
  final String? costCenterId;

  /// Find vouchers where this account is EITHER the affected OR the counterparty.
  final AccountId? involvedAccountId;

  /// Find vouchers where any side belongs to this root hierarchy.
  final AccountId? involvedRootAccountId;

  /// Optional second root for pair-based filtering (e.g., Fund Root -> Expenses Root).
  final AccountId? involvedCounterRootAccountId;

  /// If true, only show vouchers that don't have external counterparty interactions (optional hint).
  final bool? isInternalOnly;

  final VoucherType? type;
  final bool? excludeTripartite;
  final bool? onlyTripartite;

  bool get isEmpty =>
      state == null &&
      dateRange == null &&
      counterpartyId == null &&
      affectedAccountId == null &&
      involvedAccountId == null &&
      involvedRootAccountId == null &&
      involvedCounterRootAccountId == null &&
      isInternalOnly == null &&
      type == null &&
      excludeTripartite == null &&
      onlyTripartite == null;
}
