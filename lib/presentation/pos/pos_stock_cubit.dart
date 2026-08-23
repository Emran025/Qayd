import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/pos/get_pos_stock_balance_use_case.dart';
import 'package:qayd/application/pos/record_pos_stock_movement_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_stock_movement.dart';

/// Stable presentation state for one product/warehouse stock balance.
enum PosStockStatus { initial, loading, ready, recording, failure }

final class PosStockState {
  const PosStockState({
    this.status = PosStockStatus.initial,
    this.balance,
    this.failure,
    this.productId,
    this.warehouseId,
  });

  final PosStockStatus status;
  final PosStockBalance? balance;
  final Failure? failure;
  final String? productId;
  final String? warehouseId;

  bool get isBusy =>
      status == PosStockStatus.loading || status == PosStockStatus.recording;

  PosStockState copyWith({
    PosStockStatus? status,
    PosStockBalance? balance,
    Failure? failure,
    String? productId,
    String? warehouseId,
    bool clearFailure = false,
    bool clearBalance = false,
  }) {
    return PosStockState(
      status: status ?? this.status,
      balance: clearBalance ? null : balance ?? this.balance,
      failure: clearFailure ? null : failure ?? this.failure,
      productId: productId ?? this.productId,
      warehouseId: warehouseId ?? this.warehouseId,
    );
  }
}

final class PosStockCubit extends Cubit<PosStockState> {
  PosStockCubit({
    required GetPosStockBalanceUseCase getBalanceUseCase,
    required RecordPosStockMovementUseCase recordMovementUseCase,
  })  : _getBalanceUseCase = getBalanceUseCase,
        _recordMovementUseCase = recordMovementUseCase,
        super(const PosStockState());

  final GetPosStockBalanceUseCase _getBalanceUseCase;
  final RecordPosStockMovementUseCase _recordMovementUseCase;

  Future<void> loadBalance(GetPosStockBalanceInput input) async {
    if (isClosed || state.isBusy) return;
    await _loadBalance(input);
  }

  Future<void> _loadBalance(GetPosStockBalanceInput input) async {
    if (isClosed) return;
    final productId = input.productId.trim();
    final warehouseId = input.warehouseId.trim();
    emit(
      state.copyWith(
        status: PosStockStatus.loading,
        productId: productId,
        warehouseId: warehouseId,
        clearFailure: true,
        clearBalance: true,
      ),
    );

    final result = await _getBalanceUseCase(
      GetPosStockBalanceInput(
        productId: productId,
        warehouseId: warehouseId,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosStockStatus.failure,
          failure: failure,
        ),
      ),
      (balance) => emit(
        state.copyWith(
          status: PosStockStatus.ready,
          balance: balance,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> record(RecordPosStockMovementInput input) async {
    if (isClosed || state.isBusy) return;
    emit(
      state.copyWith(
        status: PosStockStatus.recording,
        productId: input.productId.trim(),
        warehouseId: input.warehouseId.trim(),
        clearFailure: true,
      ),
    );
    final result = await _recordMovementUseCase(input);
    if (isClosed) return;
    if (result.isFailure) {
      emit(
        state.copyWith(
          status: PosStockStatus.failure,
          failure: result.failureOrNull,
        ),
      );
      return;
    }
    await _loadBalance(
      GetPosStockBalanceInput(
        productId: input.productId,
        warehouseId: input.warehouseId,
      ),
    );
  }
}
