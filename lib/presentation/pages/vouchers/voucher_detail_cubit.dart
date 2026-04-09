import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/vouchers/confirm_voucher_use_case.dart';
import 'package:qayd/application/vouchers/withdraw_voucher_use_case.dart';
import 'package:qayd/application/vouchers/dtos/confirm_voucher_input.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_input.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/application/vouchers/get_voucher_details_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';

sealed class VoucherDetailState {
  const VoucherDetailState();
}

final class VoucherDetailInitial extends VoucherDetailState {
  const VoucherDetailInitial();
}

final class VoucherDetailLoading extends VoucherDetailState {
  const VoucherDetailLoading();
}

final class VoucherDetailReady extends VoucherDetailState {
  const VoucherDetailReady(
    this.data, {
    this.confirming = false,
    this.confirmErrorAr,
    this.showPostConfirmMessage = false,
  });

  final GetVoucherDetailsOutput data;
  final bool confirming;
  final String? confirmErrorAr;
  final bool showPostConfirmMessage;
}

final class VoucherDetailFailure extends VoucherDetailState {
  const VoucherDetailFailure(this.failure);

  final Failure failure;
}

class VoucherDetailCubit extends Cubit<VoucherDetailState> {
  VoucherDetailCubit(
    this._getDetails,
    this._confirm,
    this._withdraw,
  ) : super(const VoucherDetailInitial());

  final GetVoucherDetailsUseCase _getDetails;
  final ConfirmVoucherUseCase _confirm;
  final WithdrawVoucherUseCase _withdraw;

  Future<void> load(String voucherId) async {
    emit(const VoucherDetailLoading());
    await _emitDetails(voucherId, showPostConfirmMessage: false);
  }

  Future<void> _emitDetails(
    String voucherId, {
    required bool showPostConfirmMessage,
  }) async {
    final result = await _getDetails(
      GetVoucherDetailsInput(voucherId: voucherId),
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (f) => emit(VoucherDetailFailure(f)),
      (data) => emit(
        VoucherDetailReady(
          data,
          showPostConfirmMessage: showPostConfirmMessage,
        ),
      ),
    );
  }

  Future<void> confirm() async {
    final s = state;
    if (s is! VoucherDetailReady || s.confirming) {
      return;
    }
    if (s.data.stateCode != 'draft') {
      return;
    }
    emit(
      VoucherDetailReady(
        s.data,
        confirming: true,
        confirmErrorAr: null,
      ),
    );
    final result = await _confirm(
      ConfirmVoucherInput(voucherId: s.data.id),
    );
    if (isClosed) {
      return;
    }
    if (result.isFailure) {
      emit(
        VoucherDetailReady(
          s.data,
          confirming: false,
          confirmErrorAr: result.failureOrNull!.messageAr,
        ),
      );
      return;
    }
    emit(const VoucherDetailLoading());
    await _emitDetails(s.data.id, showPostConfirmMessage: true);
  }

  void clearConfirmError() {
    final s = state;
    if (s is VoucherDetailReady && s.confirmErrorAr != null) {
      emit(VoucherDetailReady(s.data));
    }
  }

  void clearPostConfirmMessage() {
    final s = state;
    if (s is VoucherDetailReady && s.showPostConfirmMessage) {
      emit(VoucherDetailReady(s.data));
    }
  }

  Future<void> withdraw() async {
    final s = state;
    if (s is! VoucherDetailReady || s.confirming) return;

    emit(VoucherDetailReady(s.data, confirming: true));
    final result = await _withdraw(voucherId: s.data.id);

    if (isClosed) return;

    if (result.isFailure) {
      emit(VoucherDetailReady(
        s.data,
        confirming: false,
        confirmErrorAr: result.failureOrNull!.messageAr,
      ));
      return;
    }

    emit(const VoucherDetailLoading());
    await _emitDetails(s.data.id, showPostConfirmMessage: false);
  }
}
