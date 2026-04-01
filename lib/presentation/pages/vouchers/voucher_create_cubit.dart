import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/vouchers/create_tripartite_transfer_use_case.dart';
import 'package:qayd/application/vouchers/create_voucher_use_case.dart';
import 'package:qayd/application/vouchers/dtos/create_tripartite_transfer_input.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';

sealed class VoucherCreateState {
  const VoucherCreateState();
}

final class VoucherCreateIdle extends VoucherCreateState {
  const VoucherCreateIdle();
}

final class VoucherCreateSubmitting extends VoucherCreateState {
  const VoucherCreateSubmitting();
}

final class VoucherCreateSuccess extends VoucherCreateState {
  const VoucherCreateSuccess(this.voucherId);

  final String voucherId;
}

/// Success state for tripartite transfers — returns both voucher IDs.
final class VoucherCreateTripartiteSuccess extends VoucherCreateState {
  const VoucherCreateTripartiteSuccess({
    required this.receiptVoucherId,
    required this.paymentVoucherId,
    required this.transferGroupId,
  });

  final String receiptVoucherId;
  final String paymentVoucherId;
  final String transferGroupId;
}

final class VoucherCreateFailure extends VoucherCreateState {
  const VoucherCreateFailure(this.failure);

  final Failure failure;
}

class VoucherCreateCubit extends Cubit<VoucherCreateState> {
  VoucherCreateCubit(this._create, this._createTripartite)
      : super(const VoucherCreateIdle());

  final CreateVoucherUseCase _create;
  final CreateTripartiteTransferUseCase _createTripartite;

  Future<void> submit(CreateVoucherInput input) async {
    emit(const VoucherCreateSubmitting());
    final result = await _create(input);
    result.fold(
      (f) => emit(VoucherCreateFailure(f)),
      (out) => emit(VoucherCreateSuccess(out.voucherId)),
    );
  }

  Future<void> submitTripartite(CreateTripartiteTransferInput input) async {
    emit(const VoucherCreateSubmitting());
    final result = await _createTripartite(input);
    result.fold(
      (f) => emit(VoucherCreateFailure(f)),
      (out) => emit(VoucherCreateTripartiteSuccess(
        receiptVoucherId: out.receiptVoucherId,
        paymentVoucherId: out.paymentVoucherId,
        transferGroupId: out.transferGroupId,
      )),
    );
  }
}
