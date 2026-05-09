import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/vouchers/dtos/advanced_filter_input.dart';
import 'package:qayd/application/vouchers/dtos/list_vouchers_input.dart';
import 'package:qayd/application/vouchers/dtos/voucher_summary_dto.dart';
import 'package:qayd/application/vouchers/list_vouchers_use_case.dart';
import 'package:qayd/application/fiscal/fiscal_period_policy.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/fiscal_period.dart';
import 'package:qayd/domain/entities/notification_message.dart';
import 'package:qayd/domain/repositories/fiscal_period_repository.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_row.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_list_state.dart';

class VoucherListCubit extends Cubit<VoucherListState> {
  VoucherListCubit(
    this._listVouchers,
    this._notificationRepo,
    this._fiscalPeriodRepository, {
    AdvancedFilterInput? initialFilter,
    bool? isInternalOnly,
  }) : super(const VoucherListInitial()) {
    _advancedFilter =
        initialFilter ?? AdvancedFilterInput(isInternalOnly: isInternalOnly);
  }

  final ListVouchersUseCase _listVouchers;
  final NotificationMessageRepository _notificationRepo;
  final FiscalPeriodRepository _fiscalPeriodRepository;

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
    _advancedFilter = AdvancedFilterInput(isInternalOnly: _advancedFilter.isInternalOnly);
    _searchDebounce?.cancel();
    _fetch();
  }

  Future<void> _fetch() async {
    emit(const VoucherListLoading());
    final filter = _advancedFilter.hasAny ? _advancedFilter : AdvancedFilterInput.empty;
    final result = await _listVouchers(
      ListVouchersInput(
        searchQuery: _searchQuery,
        advancedFilter: filter,
        excludeTripartite: true,
      ),
    );
    if (isClosed) return;

    final fiscalR = await _fiscalPeriodRepository.listAllOrdered();
    final periods =
        fiscalR.isSuccess ? fiscalR.valueOrNull! : const <FiscalPeriod>[];

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
          ..sort((a, b) {
            final dateCmp = b.dateIso.compareTo(a.dateIso);
            if (dateCmp != 0) return dateCmp;
            return b.createdAtIso.compareTo(a.createdAtIso);
          });
        final rows = _buildRows(sorted, periods);
        emit(
          VoucherListReady(
            rows: rows,
            searchQuery: _searchQuery,
            advancedFilter: _advancedFilter,
            accountNamesById: Map<String, String>.from(_accountNamesById),
            mergeProposals: proposals,
          ),
        );
      },
    );
  }

  List<VoucherListRow> _buildRows(
    List<VoucherSummaryDto> sorted,
    List<FiscalPeriod> periods,
  ) {
    if (periods.isEmpty) {
      return sorted.map<VoucherListRow>(VoucherListVoucherRow.new).toList();
    }
    final rows = <VoucherListRow>[];
    FiscalPeriod? prevPeriod;
    for (final v in sorted) {
      final vd = DateTime.parse(v.dateIso);
      final p = FiscalPeriodPolicy.periodContaining(periods, vd);
      if (prevPeriod?.id != p?.id) {
        if (p != null) {
          final suffix = p.status == FiscalPeriodStatus.closed
              ? AppStrings.fiscalPeriodDividerClosed
              : AppStrings.fiscalPeriodDividerOpen;
          rows.add(
            VoucherListPeriodDivider(
              label: '${p.name} — $suffix',
              isClosed: p.status == FiscalPeriodStatus.closed,
            ),
          );
        }
      }
      rows.add(VoucherListVoucherRow(v));
      if (v.stateCode == 'settled' &&
          v.senderStatusCode == 'accepted' &&
          v.receiverStatusCode == 'accepted') {
        rows.add(
          VoucherListSettlementRow(
            label: AppStrings.statementSettlementMilestone,
            currencyCode: v.currencyCode,
            balanceMinorUnits: null,
          ),
        );
      }
      prevPeriod = p;
    }
    return rows;
  }
}
