import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/accounts/dtos/statement_chat_filter_input.dart';
import 'package:qayd/application/accounts/list_account_statement_chat_use_case.dart';
import 'package:qayd/application/accounts/list_accounts_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_state.dart';

class StatementChatCubit extends Cubit<StatementChatState> {
  StatementChatCubit({
    required ListAccountStatementChatUseCase listStatement,
    required ListAccountsUseCase listAccounts,
    required String counterpartyAccountId,
    String? myAccountId,
  })  : _listStatement = listStatement,
        _listAccounts = listAccounts,
        _counterpartyAccountId = counterpartyAccountId,
        _initialMyAccountId = myAccountId,
        super(const StatementChatInitial());

  final ListAccountStatementChatUseCase _listStatement;
  final ListAccountsUseCase _listAccounts;
  final String _counterpartyAccountId;
  final String? _initialMyAccountId;

  String _myAccountId = '';
  String _counterpartyName = '';
  String _searchQuery = '';
  bool _isFund = false;
  StatementChatFilterInput _filter = StatementChatFilterInput.empty;
  Timer? _searchDebounce;

  String get searchQuery => _searchQuery;
  StatementChatFilterInput get filter => _filter;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(const StatementChatLoading());

    // Resolve accounts to find "my" account and counterparty name.
    final accountsR = await _listAccounts.call(
      const ListAccountsInput(activeOnly: false),
    );
    if (accountsR.isFailure) {
      emit(StatementChatFailure(accountsR.failureOrNull!));
      return;
    }

    final accounts = accountsR.valueOrNull!.accounts;
    final cp = accounts.firstWhere(
      (a) => a.id == _counterpartyAccountId,
      orElse: () => accounts.first,
    );
    _counterpartyName = cp.name;
    _isFund = cp.standardClassificationKind ==
        StandardAccountClassificationKind.liquidAssets.name;

    // Pick the "my" account. If provided initially, use it. Otherwise find first one.
    if (_initialMyAccountId != null) {
      _myAccountId = _initialMyAccountId!;
    } else {
      final my = accounts.firstWhere(
        (a) => a.id != cp.id,
        orElse: () => accounts.first,
    );
      _myAccountId = my.id;
    }

    await _fetch();
  }

  void setSearchText(String text) {
    _searchQuery = text;
    final s = state;
    if (s is StatementChatReady) {
      emit(s.copyWith(searchQuery: text));
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), _fetch);
  }

  void setFilter(StatementChatFilterInput filter) {
    _filter = filter;
    _fetch();
  }

  void setViewMode(StatementChatViewMode mode) {
    _filter = _filter.copyWith(viewMode: mode);
    _fetch();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchDebounce?.cancel();
    _fetch();
  }

  void clearAllFiltersAndSearch() {
    _searchQuery = '';
    _filter = StatementChatFilterInput.empty;
    _searchDebounce?.cancel();
    _fetch();
  }


  Future<void> reload() => _fetch();

  Future<void> _fetch() async {
    final activeFilter = _filter.copyWith(
      searchQuery: _searchQuery.trim().isEmpty ? null : _searchQuery,
      clearSearchQuery: _searchQuery.trim().isEmpty,
    );

    final result = await _listStatement.call(
      myAccountId: _myAccountId,
      counterpartyAccountId: _counterpartyAccountId,
      filter: activeFilter,
      isUnified: _isFund,
    );

    result.fold(
      (f) => emit(StatementChatFailure(f)),
      (out) {
        // Infer currency from first message if available.
        String currSymbol = '';
        int currDigits = 0;
        if (out.messages.isNotEmpty) {
          currSymbol = out.messages.first.currencySymbol;
          currDigits = out.messages.first.currencyDigits;
        }

        emit(StatementChatReady(
          myAccountId: _myAccountId,
          counterpartyAccountId: _counterpartyAccountId,
          counterpartyName: _counterpartyName,
          messages: out.messages,
          broughtForwardMinorUnits: out.broughtForwardMinorUnits,
          finalBalanceMinorUnits: out.finalBalanceMinorUnits,
          filter: _filter,
          searchQuery: _searchQuery,
          isUnified: _isFund,
          currencySymbol: currSymbol,
          currencyDigits: currDigits,
        ));
      },
    );
  }
}
