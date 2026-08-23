import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_stock_movement.dart';
import 'package:qayd/domain/repositories/pos_stock_movement_repository.dart';

final class GetPosStockBalanceInput {
  const GetPosStockBalanceInput({
    required this.productId,
    required this.warehouseId,
  });

  final String productId;
  final String warehouseId;
}

final class GetPosStockBalanceUseCase {
  GetPosStockBalanceUseCase(this._repository);

  final PosStockMovementRepository _repository;

  Future<Result<PosStockBalance>> call(GetPosStockBalanceInput input) {
    return _repository.getBalance(
      productId: input.productId,
      warehouseId: input.warehouseId,
    );
  }
}
