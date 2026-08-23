import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/domain/entities/pos_stock_movement.dart';
import 'package:qayd/domain/exceptions/invalid_pos_stock_exception.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/pos_quantity.dart';

CurrencyCode _currency() => CurrencyCode(
      code: 'SAR',
      nameAr: 'ريال',
      symbol: 'ر.س',
    );

PosStockMovement _movement({
  required CurrencyCode currency,
  required String id,
  required PosStockMovementType type,
  required PosStockMovementDirection direction,
  required int quantity,
  required int cost,
  int scale = 0,
}) {
  return PosStockMovement.create(
    id: id,
    productId: 'product-1',
    warehouseId: 'warehouse-1',
    type: type,
    direction: direction,
    quantity: PosQuantity.fromScaled(quantity, scale: scale, allowZero: false),
    unitCost: Money.fromMinorUnits(cost, currency),
    occurredAt: DateTime.utc(2026, 1, 1),
    idempotencyKey: 'key-$id',
  );
}

void main() {
  test('replays inbound movements using exact weighted average', () {
    final currency = _currency();
    var balance = emptyPosStockBalance(currency: currency, quantityScale: 0);

    balance = balance.apply(
      _movement(
        currency: currency,
        id: 'opening',
        type: PosStockMovementType.opening,
        direction: PosStockMovementDirection.inbound,
        quantity: 10,
        cost: 100,
      ),
    );
    balance = balance.apply(
      _movement(
        currency: currency,
        id: 'purchase',
        type: PosStockMovementType.purchase,
        direction: PosStockMovementDirection.inbound,
        quantity: 10,
        cost: 200,
      ),
    );

    expect(balance.quantity.scaledUnits, 20);
    expect(balance.valuation.minorUnits, 3000);
    expect(balance.averageUnitCost.minorUnits, 150);
  });

  test('outbound movement consumes at current average cost', () {
    final currency = _currency();
    var balance = PosStockBalance(
      quantity: PosQuantity.whole(20),
      valuation: Money.fromMinorUnits(3000, currency),
    );

    balance = balance.apply(
      _movement(
        currency: currency,
        id: 'sale',
        type: PosStockMovementType.sale,
        direction: PosStockMovementDirection.outbound,
        quantity: 5,
        cost: 999,
      ),
    );

    expect(balance.quantity.scaledUnits, 15);
    expect(balance.valuation.minorUnits, 2250);
    expect(balance.averageUnitCost.minorUnits, 150);
  });

  test('rejects an outbound movement that would make stock negative', () {
    final currency = _currency();
    final balance = PosStockBalance(
      quantity: PosQuantity.whole(2),
      valuation: Money.fromMinorUnits(200, currency),
    );

    expect(
      () => balance.apply(
        _movement(
          currency: currency,
          id: 'sale-too-large',
          type: PosStockMovementType.sale,
          direction: PosStockMovementDirection.outbound,
          quantity: 3,
          cost: 100,
        ),
      ),
      throwsA(isA<InvalidPosStockException>()),
    );
  });

  test('requires explicit direction for adjustment movements', () {
    final currency = _currency();

    expect(
      () => PosStockMovement.create(
        id: 'adjustment',
        productId: 'product-1',
        warehouseId: 'warehouse-1',
        type: PosStockMovementType.adjustment,
        quantity: PosQuantity.whole(1),
        unitCost: Money.zero(currency),
        occurredAt: DateTime.utc(2026, 1, 1),
        idempotencyKey: 'adjustment-key',
      ),
      throwsA(isA<InvalidPosStockException>()),
    );
  });

  test('rejects scale and currency mismatches', () {
    final currency = _currency();
    final otherCurrency = CurrencyCode(
      code: 'USD',
      nameAr: 'دولار',
      symbol: '\$',
    );
    final balance = PosStockBalance(
      quantity: PosQuantity.whole(1),
      valuation: Money.zero(currency),
    );

    expect(
      () => balance.apply(
        _movement(
          currency: currency,
          id: 'scale-mismatch',
          type: PosStockMovementType.purchase,
          direction: PosStockMovementDirection.inbound,
          quantity: 1,
          cost: 100,
          scale: 2,
        ),
      ),
      throwsA(isA<InvalidPosStockException>()),
    );
    expect(
      () => balance.apply(
        _movement(
          currency: otherCurrency,
          id: 'currency-mismatch',
          type: PosStockMovementType.purchase,
          direction: PosStockMovementDirection.inbound,
          quantity: 1,
          cost: 100,
        ),
      ),
      throwsA(isA<InvalidPosStockException>()),
    );
  });
}
