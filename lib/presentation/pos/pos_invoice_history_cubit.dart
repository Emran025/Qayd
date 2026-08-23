import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/pos/list_pos_invoices_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/domain/entities/pos_invoice.dart';

enum PosInvoiceHistoryStatus { initial, loading, ready, failure }

final class PosInvoiceHistoryState {
  const PosInvoiceHistoryState({
    this.status = PosInvoiceHistoryStatus.initial,
    this.invoices = const <PosInvoice>[],
    this.failure,
  });

  final PosInvoiceHistoryStatus status;
  final List<PosInvoice> invoices;
  final Failure? failure;

  PosInvoiceHistoryState copyWith({
    PosInvoiceHistoryStatus? status,
    List<PosInvoice>? invoices,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      PosInvoiceHistoryState(
        status: status ?? this.status,
        invoices: invoices ?? this.invoices,
        failure: clearFailure ? null : failure ?? this.failure,
      );
}

final class PosInvoiceHistoryCubit extends Cubit<PosInvoiceHistoryState> {
  PosInvoiceHistoryCubit({required ListPosInvoicesUseCase listInvoices})
      : _listInvoices = listInvoices,
        super(const PosInvoiceHistoryState());

  final ListPosInvoicesUseCase _listInvoices;

  Future<void> load() async {
    if (isClosed || state.status == PosInvoiceHistoryStatus.loading) return;
    emit(state.copyWith(
        status: PosInvoiceHistoryStatus.loading, clearFailure: true));
    final result = await _listInvoices(type: PosInvoiceType.sale, limit: 100);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        status: PosInvoiceHistoryStatus.failure,
        failure: failure,
      )),
      (invoices) => emit(state.copyWith(
        status: PosInvoiceHistoryStatus.ready,
        invoices: List.unmodifiable(invoices),
        clearFailure: true,
      )),
    );
  }
}
