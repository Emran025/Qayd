import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_stock_movement.dart';

abstract interface class PosStockMovementRepository {
  Future<Result<PosStockBalance>> getBalance({
    required String productId,
    required String warehouseId,
  });

  Future<Result<PosStockMovement?>> getByIdempotencyKey(String key);

  Future<Result<void>> append(PosStockMovement movement);
}
