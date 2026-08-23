import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_stock_movement.dart';
import 'package:qayd/domain/exceptions/invalid_pos_stock_exception.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/repositories/pos_stock_movement_repository.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/pos_quantity.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// SQLite adapter for immutable POS stock movements and deterministic balance replay.
final class SqlitePosStockMovementRepository
    implements PosStockMovementRepository {
  SqlitePosStockMovementRepository(this._db, this._currencyRepository);

  final Database _db;
  final CurrencyRepository _currencyRepository;

  @override
  Future<Result<PosStockBalance>> getBalance({
    required String productId,
    required String warehouseId,
  }) async {
    try {
      final productRows = await _db.query(
        'pos_products',
        columns: ['currency_code', 'quantity_scale'],
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (productRows.isEmpty) return _productNotFound();
      final currency = await _currency(productRows.first['currency_code']);
      if (currency.isFailure) {
        return FailureResult(currency.failureOrNull!);
      }
      final resolvedCurrency = currency.valueOrNull!;
      final scale = _asInt(productRows.first['quantity_scale']);
      var balance = emptyPosStockBalance(
        currency: resolvedCurrency,
        quantityScale: scale,
      );
      final rows = await _db.query(
        'pos_stock_movements',
        where: 'product_id = ? AND warehouse_id = ?',
        whereArgs: [productId, warehouseId],
        orderBy: 'occurred_at ASC, created_at ASC, id ASC',
      );
      for (final row in rows) {
        final movementResult = await _mapRow(row);
        if (movementResult.isFailure) {
          return FailureResult(movementResult.failureOrNull!);
        }
        try {
          balance = balance.apply(movementResult.valueOrNull!);
        } on InvalidPosStockException catch (error) {
          return FailureResult(ValidationFailure(messageAr: error.messageAr));
        }
      }
      return Success(balance);
    } on DatabaseException {
      return _readFailure();
    } on InvalidPosStockException catch (error) {
      return FailureResult(ValidationFailure(messageAr: error.messageAr));
    } catch (_) {
      return _readFailure();
    }
  }

  @override
  Future<Result<PosStockMovement?>> getByIdempotencyKey(String key) async {
    final normalized = key.trim();
    if (normalized.isEmpty) return const Success(null);
    try {
      final rows = await _db.query(
        'pos_stock_movements',
        where: 'idempotency_key = ?',
        whereArgs: [normalized],
        limit: 1,
      );
      if (rows.isEmpty) return const Success(null);
      final mapped = await _mapRow(rows.first);
      if (mapped.isFailure) {
        return FailureResult<PosStockMovement?>(mapped.failureOrNull!);
      }
      return Success<PosStockMovement?>(mapped.valueOrNull);
    } on DatabaseException {
      return _readNullableFailure();
    } on InvalidPosStockException catch (error) {
      return FailureResult(ValidationFailure(messageAr: error.messageAr));
    } catch (_) {
      return _readNullableFailure();
    }
  }

  @override
  Future<Result<void>> append(PosStockMovement movement) async {
    try {
      await _db.transaction((txn) async {
        final duplicate = await txn.query(
          'pos_stock_movements',
          columns: ['id'],
          where: 'idempotency_key = ?',
          whereArgs: [movement.idempotencyKey],
          limit: 1,
        );
        if (duplicate.isNotEmpty) {
          throw const _StockMovementIdempotencyConflictException();
        }
        await txn.insert(
          'pos_stock_movements',
          _toRow(movement),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      });
      return const Success(null);
    } on _StockMovementIdempotencyConflictException {
      return FailureResult(
        ValidationFailure(messageAr: AppStrings.posStockIdempotencyExists),
      );
    } on DatabaseException {
      return FailureResult(
        DatabaseFailure(messageAr: AppStrings.posStockAppendFailed),
      );
    } catch (_) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStrings.posStockAppendFailed),
      );
    }
  }

  Future<Result<PosStockMovement>> _mapRow(Map<String, Object?> row) async {
    final currency = await _currency(row['currency_code']);
    if (currency.isFailure) return FailureResult(currency.failureOrNull!);
    final signed = _asInt(row['quantity_scaled']);
    if (signed == 0) {
      return FailureResult(
        ValidationFailure(messageAr: AppStrings.posStockInvalidMovement),
      );
    }
    final type = _typeFromDb(row['movement_type'] as String?);
    if (type == null) {
      return FailureResult(
        ValidationFailure(messageAr: AppStrings.posStockInvalidMovement),
      );
    }
    try {
      return Success(
        PosStockMovement.create(
          id: row['id']! as String,
          productId: row['product_id']! as String,
          warehouseId: row['warehouse_id']! as String,
          type: type,
          direction: signed > 0
              ? PosStockMovementDirection.inbound
              : PosStockMovementDirection.outbound,
          quantity: PosQuantity.fromScaled(
            signed.abs(),
            scale: _asInt(row['quantity_scale']),
          ),
          unitCost: Money.fromMinorUnits(
            _asInt(row['unit_cost_minor']),
            currency.valueOrNull!,
          ),
          sourceType: row['source_type'] as String?,
          sourceId: row['source_id'] as String?,
          sourceLineId: row['source_line_id'] as String?,
          lotId: row['lot_id'] as String?,
          occurredAt: DateTime.parse(row['occurred_at']! as String),
          idempotencyKey: row['idempotency_key']! as String,
          createdAt: DateTime.parse(row['created_at']! as String),
        ),
      );
    } on InvalidPosStockException catch (error) {
      return FailureResult(ValidationFailure(messageAr: error.messageAr));
    }
  }

  Future<Result<CurrencyCode>> _currency(Object? code) async {
    final currencyResult = await _currencyRepository.getByCode(code as String);
    if (currencyResult.isFailure) {
      return FailureResult(currencyResult.failureOrNull!);
    }
    final currency = currencyResult.valueOrNull;
    if (currency == null) {
      return FailureResult(
        ValidationFailure(messageAr: AppStrings.posStockCurrencyMismatch),
      );
    }
    return Success(currency);
  }

  Map<String, Object?> _toRow(PosStockMovement movement) => {
        'id': movement.id,
        'product_id': movement.productId,
        'warehouse_id': movement.warehouseId,
        'movement_type': _typeToDb(movement.type),
        'quantity_scaled': movement.signedQuantityScaled,
        'quantity_scale': movement.quantity.scale,
        'unit_cost_minor': movement.unitCost.minorUnits,
        'currency_code': movement.unitCost.currency.code,
        'source_type': movement.sourceType,
        'source_id': movement.sourceId,
        'source_line_id': movement.sourceLineId,
        'lot_id': movement.lotId,
        'occurred_at': movement.occurredAt.toUtc().toIso8601String(),
        'idempotency_key': movement.idempotencyKey,
        'created_at': movement.createdAt.toUtc().toIso8601String(),
      };

  static String _typeToDb(PosStockMovementType type) {
    switch (type) {
      case PosStockMovementType.opening:
        return 'opening';
      case PosStockMovementType.purchase:
        return 'purchase';
      case PosStockMovementType.sale:
        return 'sale';
      case PosStockMovementType.salesReturn:
        return 'sales_return';
      case PosStockMovementType.purchaseReturn:
        return 'purchase_return';
      case PosStockMovementType.adjustment:
        return 'adjustment';
      case PosStockMovementType.damage:
        return 'damage';
      case PosStockMovementType.expiry:
        return 'expiry';
    }
  }

  static PosStockMovementType? _typeFromDb(String? value) {
    switch (value) {
      case 'opening':
        return PosStockMovementType.opening;
      case 'purchase':
        return PosStockMovementType.purchase;
      case 'sale':
        return PosStockMovementType.sale;
      case 'sales_return':
        return PosStockMovementType.salesReturn;
      case 'purchase_return':
        return PosStockMovementType.purchaseReturn;
      case 'adjustment':
        return PosStockMovementType.adjustment;
      case 'damage':
        return PosStockMovementType.damage;
      case 'expiry':
        return PosStockMovementType.expiry;
      default:
        return null;
    }
  }

  static int _asInt(Object? value) => (value as num).toInt();

  FailureResult<PosStockBalance> _productNotFound() => FailureResult(
        ValidationFailure(messageAr: AppStrings.posProductNotFound),
      );

  FailureResult<PosStockBalance> _readFailure() => FailureResult(
        DatabaseFailure(messageAr: AppStrings.posStockReadFailed),
      );

  FailureResult<PosStockMovement?> _readNullableFailure() => FailureResult(
        DatabaseFailure(messageAr: AppStrings.posStockReadFailed),
      );
}

final class _StockMovementIdempotencyConflictException implements Exception {
  const _StockMovementIdempotencyConflictException();
}
