import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/core/error/failures.dart';

enum AccountNatureFilter { all, debit, credit }

sealed class AccountListState {
  const AccountListState();
}

final class AccountListInitial extends AccountListState {
  const AccountListInitial();
}

final class AccountListLoading extends AccountListState {
  const AccountListLoading();
}

final class AccountListReady extends AccountListState {
  const AccountListReady({
    required this.allAccounts,
    required this.searchQuery,
    required this.natureFilter,
  });

  final List<AccountSummaryDto> allAccounts;
  final String searchQuery;
  final AccountNatureFilter natureFilter;

  List<AccountSummaryDto> get filteredAccounts {
    var list = allAccounts;
    if (natureFilter == AccountNatureFilter.debit) {
      list = list.where((a) => a.natureCode == 'debit').toList();
    } else if (natureFilter == AccountNatureFilter.credit) {
      list = list.where((a) => a.natureCode == 'credit').toList();
    }
    final q = searchQuery.trim();
    if (q.isNotEmpty) {
      list = list.where((a) => a.name.contains(q)).toList();
    }
    return list;
  }

  AccountListReady copyWith({
    List<AccountSummaryDto>? allAccounts,
    String? searchQuery,
    AccountNatureFilter? natureFilter,
  }) {
    return AccountListReady(
      allAccounts: allAccounts ?? this.allAccounts,
      searchQuery: searchQuery ?? this.searchQuery,
      natureFilter: natureFilter ?? this.natureFilter,
    );
  }
}

final class AccountListFailure extends AccountListState {
  const AccountListFailure(this.failure);

  final Failure failure;
}
