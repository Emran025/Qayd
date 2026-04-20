import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/vouchers/dtos/advanced_filter_input.dart';
import 'package:qayd/application/vouchers/dtos/list_vouchers_input.dart';
import 'package:qayd/application/vouchers/dtos/tripartite_transfer_summary_dto.dart';
import 'package:qayd/application/vouchers/list_vouchers_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/pages/vouchers/tripartite_list_state.dart';

class TripartiteListCubit extends Cubit<TripartiteListState> {
  TripartiteListCubit(this._listVouchers)
      : super(const TripartiteListInitial());

  final ListVouchersUseCase _listVouchers;

  String _searchQuery = '';
  AdvancedFilterInput _advancedFilter = AdvancedFilterInput.empty;
  Timer? _searchDebounce;

  String get searchQuery => _searchQuery;
  AdvancedFilterInput get advancedFilter => _advancedFilter;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> load() => _fetch();

  void setSearchText(String text) {
    _searchQuery = text;
    final s = state;
    if (s is TripartiteListReady) {
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
    emit(const TripartiteListLoading());
    final result = await _listVouchers(
      ListVouchersInput(
        searchQuery: _searchQuery,
        advancedFilter: _advancedFilter.hasAny ? _advancedFilter : null,
        onlyTripartite: true,
      ),
    );
    result.fold(
      (f) => emit(TripartiteListFailure(f)),
      (out) {
        final Map<String, TripartiteTransferSummaryDto> groups = {};
        final Map<String, String> names = {};

        for (final v in out.vouchers) {
          names[v.counterpartyAccountId] = v.counterpartyName;
          names[v.affectedAccountId] = v.affectedName;

          if (v.transferGroupId == null) continue;
          final gid = v.transferGroupId!;

          final isReceipt = v.typeCode == VoucherType.receipt.name;
          final isPayment = v.typeCode == VoucherType.payment.name;

          // Skip fee vouchers: they share the same transferGroupId but
          // their tripartiteRole is 'intermediary_receipt' while being a
          // receipt whose affectedAccount differs from the main legs.
          // We detect them by checking if a group already exists and
          // the new voucher's affectedAccountId differs from the existing one.
          final existingGroup = groups[gid];
          if (existingGroup != null) {
            final existingAffectedId =
                existingGroup.receiptVoucher?.affectedAccountId ??
                    existingGroup.paymentVoucher?.affectedAccountId;
            if (existingAffectedId != null &&
                existingAffectedId != v.affectedAccountId) {
              // This is a fee voucher — skip it.
              continue;
            }
          }

          groups.putIfAbsent(gid, () {
            String sourceName = '';
            String destinationName = '';
            if (isReceipt) {
              sourceName = v.counterpartyName;
            } else if (isPayment) {
              destinationName = v.counterpartyName;
            }
            return TripartiteTransferSummaryDto(
              transferGroupId: gid,
              dateIso: v.dateIso,
              amountMinorUnits: v.amountMinorUnits,
              currencyCode: v.currencyCode,
              currencySymbol: v.currencySymbol,
              currencyDigits: v.currencyDigits,
              currencyNameAr: v.currencyNameAr,
              sourceName: sourceName,
              destinationName: destinationName,
              affectedName: v.affectedName,
              receiptVoucher: isReceipt ? v : null,
              paymentVoucher: isPayment ? v : null,
            );
          });

          final existing = groups[gid]!;
          // If existing was created from a fee voucher (wrong affected), fix it
          if (existing.receiptVoucher == null && existing.paymentVoucher == null) {
            // First real leg — replace the stub entirely
            groups[gid] = TripartiteTransferSummaryDto(
              transferGroupId: gid,
              dateIso: v.dateIso,
              amountMinorUnits: v.amountMinorUnits,
              currencyCode: v.currencyCode,
              currencySymbol: v.currencySymbol,
              currencyDigits: v.currencyDigits,
              currencyNameAr: v.currencyNameAr,
              sourceName: isReceipt ? v.counterpartyName : '',
              destinationName: isPayment ? v.counterpartyName : '',
              affectedName: v.affectedName,
              receiptVoucher: isReceipt ? v : null,
              paymentVoucher: isPayment ? v : null,
            );
          } else {
            // Update missing info from the second leg
            groups[gid] = TripartiteTransferSummaryDto(
              transferGroupId: gid,
              dateIso: existing.dateIso,
              amountMinorUnits: existing.amountMinorUnits,
              currencyCode: existing.currencyCode,
              currencySymbol: existing.currencySymbol,
              currencyDigits: existing.currencyDigits,
              currencyNameAr: existing.currencyNameAr,
              sourceName:
                  isReceipt ? v.counterpartyName : existing.sourceName,
              destinationName:
                  isPayment ? v.counterpartyName : existing.destinationName,
              affectedName: existing.affectedName,
              receiptVoucher: isReceipt ? v : existing.receiptVoucher,
              paymentVoucher: isPayment ? v : existing.paymentVoucher,
            );
          }
        }

        final sorted = groups.values.toList()
          ..sort((a, b) => b.dateIso.compareTo(a.dateIso));

        emit(
          TripartiteListReady(
            transfers: sorted,
            searchQuery: _searchQuery,
            advancedFilter: _advancedFilter,
            accountNamesById: names,
          ),
        );
      },
    );
  }
}
