import 'package:qayd/application/vouchers/dtos/advanced_filter_input.dart';
import 'package:qayd/domain/entities/notification_message.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_row.dart';

sealed class VoucherListState {
  const VoucherListState();
}

final class VoucherListInitial extends VoucherListState {
  const VoucherListInitial();
}

final class VoucherListLoading extends VoucherListState {
  const VoucherListLoading();
}

final class VoucherListReady extends VoucherListState {
  const VoucherListReady({
    required this.rows,
    required this.searchQuery,
    required this.advancedFilter,
    required this.accountNamesById,
    this.mergeProposals = const [],
  });

  final List<VoucherListRow> rows;
  final String searchQuery;
  final AdvancedFilterInput advancedFilter;
  final Map<String, String> accountNamesById;
  final List<NotificationMessage> mergeProposals;

  bool get hasActiveQuery =>
      searchQuery.trim().isNotEmpty || advancedFilter.hasAny;

  VoucherListReady copyWith({
    List<VoucherListRow>? rows,
    String? searchQuery,
    AdvancedFilterInput? advancedFilter,
    Map<String, String>? accountNamesById,
    List<NotificationMessage>? mergeProposals,
  }) {
    return VoucherListReady(
      rows: rows ?? this.rows,
      searchQuery: searchQuery ?? this.searchQuery,
      advancedFilter: advancedFilter ?? this.advancedFilter,
      accountNamesById: accountNamesById ?? this.accountNamesById,
      mergeProposals: mergeProposals ?? this.mergeProposals,
    );
  }
}

final class VoucherListFailure extends VoucherListState {
  const VoucherListFailure(this.failure);

  final Failure failure;
}
