import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/vouchers/dtos/advanced_filter_input.dart';
import 'package:qayd/application/vouchers/dtos/list_vouchers_input.dart';
import 'package:qayd/application/vouchers/list_vouchers_use_case.dart';
import 'package:qayd/domain/entities/notification_message.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_state.dart';

class VoucherListCubit extends Cubit<VoucherListState> {
  VoucherListCubit(
    this._listVouchers,
    this._notificationRepo,
  ) : super(const VoucherListInitial());

  final ListVouchersUseCase _listVouchers;
  final NotificationMessageRepository _notificationRepo;

  String _searchQuery = '';
  AdvancedFilterInput _advancedFilter = AdvancedFilterInput.empty;
  Map<String, String> _accountNamesById = {};
  Timer? _searchDebounce;

  String get searchQuery => _searchQuery;
  AdvancedFilterInput get advancedFilter => _advancedFilter;
  Map<String, String> get accountNamesById => _accountNamesById;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> load() => _fetch();

  /// Updates text immediately for chips; debounces repository calls.
  void setSearchText(String text) {
    _searchQuery = text;
    final s = state;
    if (s is VoucherListReady) {
      emit(s.copyWith(searchQuery: text));
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), _fetch);
  }

  void setAdvancedFilter(AdvancedFilterInput filter) {
    _advancedFilter = filter;
    _fetch();
  }

  void patchAdvancedFilter(
      AdvancedFilterInput Function(AdvancedFilterInput) fn) {
    _advancedFilter = fn(_advancedFilter);
    _fetch();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchDebounce?.cancel();
    _fetch();
  }

  void clearAllFiltersAndSearch() {
    _searchQuery = '';
    _advancedFilter = AdvancedFilterInput.empty;
    _searchDebounce?.cancel();
    _fetch();
  }

  Future<void> _fetch() async {
    emit(const VoucherListLoading());
    final result = await _listVouchers(
      ListVouchersInput(
        searchQuery: _searchQuery,
        advancedFilter: _advancedFilter.hasAny ? _advancedFilter : null,
        excludeTripartite: true,
      ),
    );

    final proposalsResult = await _notificationRepo.listAllUnprocessed();
    final proposals = proposalsResult.isSuccess
        ? proposalsResult.valueOrNull!
            .where((e) => e.channel == 'conflict')
            .toList()
        : <NotificationMessage>[];

    result.fold(
      (f) => emit(VoucherListFailure(f)),
      (out) {
        _accountNamesById = out.accountNamesById;
        final sorted = [...out.vouchers]
          ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
        emit(
          VoucherListReady(
            vouchers: sorted,
            searchQuery: _searchQuery,
            advancedFilter: _advancedFilter,
            accountNamesById: Map<String, String>.from(_accountNamesById),
            mergeProposals: proposals,
          ),
        );
      },
    );
  }
}
