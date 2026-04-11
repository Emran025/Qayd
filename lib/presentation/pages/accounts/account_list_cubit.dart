import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/accounts/list_accounts_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/pages/accounts/account_list_state.dart';

class AccountListCubit extends Cubit<AccountListState> {
  AccountListCubit(this._listAccounts, {this.initialTypeFilter = AccountTypeFilter.child}) : super(const AccountListInitial());

  final ListAccountsUseCase _listAccounts;
  final AccountTypeFilter initialTypeFilter;

  Future<void> load() async {
    final s = state;
    if (s is! AccountListReady) {
      emit(const AccountListLoading());
    }

    final result =
        await _listAccounts(const ListAccountsInput(activeOnly: false));

    result.fold(
      (f) => emit(AccountListFailure(f)),
      (out) {
        final currentState = state;
        if (currentState is AccountListReady) {
          emit(currentState.copyWith(allAccounts: out.accounts));
        } else {
          emit(
            AccountListReady(
              allAccounts: out.accounts,
              searchQuery: '',
              natureFilter: AccountNatureFilter.all,
              typeFilter: initialTypeFilter,
            ),
          );
        }
      },
    );
  }

  void setSearchQuery(String query) {
    final s = state;
    if (s is AccountListReady) {
      emit(s.copyWith(searchQuery: query));
    }
  }

  void setNatureFilter(AccountNatureFilter filter) {
    final s = state;
    if (s is AccountListReady) {
      emit(s.copyWith(natureFilter: filter));
    }
  }

  void setTypeFilter(AccountTypeFilter filter) {
    final s = state;
    if (s is AccountListReady) {
      emit(s.copyWith(typeFilter: filter));
    }
  }
}
