import 'package:equatable/equatable.dart';
import 'package:qayd/application/vouchers/dtos/advanced_filter_input.dart';
import 'package:qayd/application/vouchers/dtos/tripartite_transfer_summary_dto.dart';
import 'package:qayd/core/error/failures.dart';

sealed class TripartiteListState extends Equatable {
  const TripartiteListState();

  @override
  List<Object?> get props => [];
}

class TripartiteListInitial extends TripartiteListState {
  const TripartiteListInitial();
}

class TripartiteListLoading extends TripartiteListState {
  const TripartiteListLoading();
}

class TripartiteListReady extends TripartiteListState {
  const TripartiteListReady({
    required this.transfers,
    this.searchQuery = '',
    this.advancedFilter = AdvancedFilterInput.empty,
    this.accountNamesById = const {},
  });

  final List<TripartiteTransferSummaryDto> transfers;
  final String searchQuery;
  final AdvancedFilterInput advancedFilter;
  final Map<String, String> accountNamesById;

  @override
  List<Object?> get props => [
        transfers,
        searchQuery,
        advancedFilter,
        accountNamesById,
      ];

  TripartiteListReady copyWith({
    List<TripartiteTransferSummaryDto>? transfers,
    String? searchQuery,
    AdvancedFilterInput? advancedFilter,
    Map<String, String>? accountNamesById,
  }) {
    return TripartiteListReady(
      transfers: transfers ?? this.transfers,
      searchQuery: searchQuery ?? this.searchQuery,
      advancedFilter: advancedFilter ?? this.advancedFilter,
      accountNamesById: accountNamesById ?? this.accountNamesById,
    );
  }
}

class TripartiteListFailure extends TripartiteListState {
  const TripartiteListFailure(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
