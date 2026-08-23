import 'package:qayd/presentation/l10n/app_strings.dart';

/// Raised when a POS stock movement violates an inventory invariant.
final class InvalidPosStockException implements Exception {
  const InvalidPosStockException({required this.messageAr, required this.code});

  final String messageAr;
  final String code;

  factory InvalidPosStockException.idRequired() => InvalidPosStockException(
        messageAr: AppStrings.posStockIdRequired,
        code: 'pos_stock_id_required',
      );

  factory InvalidPosStockException.productIdRequired() =>
      InvalidPosStockException(
        messageAr: AppStrings.posStockProductIdRequired,
        code: 'pos_stock_product_id_required',
      );

  factory InvalidPosStockException.warehouseIdRequired() =>
      InvalidPosStockException(
        messageAr: AppStrings.posStockWarehouseIdRequired,
        code: 'pos_stock_warehouse_id_required',
      );

  factory InvalidPosStockException.idempotencyKeyRequired() =>
      InvalidPosStockException(
        messageAr: AppStrings.posStockIdempotencyRequired,
        code: 'pos_stock_idempotency_required',
      );

  factory InvalidPosStockException.directionRequired() =>
      InvalidPosStockException(
        messageAr: AppStrings.posStockDirectionRequired,
        code: 'pos_stock_direction_required',
      );

  factory InvalidPosStockException.scaleMismatch() => InvalidPosStockException(
        messageAr: AppStrings.posStockScaleMismatch,
        code: 'pos_stock_scale_mismatch',
      );

  factory InvalidPosStockException.currencyMismatch() =>
      InvalidPosStockException(
        messageAr: AppStrings.posStockCurrencyMismatch,
        code: 'pos_stock_currency_mismatch',
      );

  factory InvalidPosStockException.insufficientStock() =>
      InvalidPosStockException(
        messageAr: AppStrings.posStockInsufficient,
        code: 'pos_stock_insufficient',
      );

  factory InvalidPosStockException.outcomeNegative() =>
      InvalidPosStockException(
        messageAr: AppStrings.posStockNegativeResult,
        code: 'pos_stock_negative_result',
      );

  @override
  String toString() => 'InvalidPosStockException($code): $messageAr';
}
