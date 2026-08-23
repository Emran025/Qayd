# POS stock foundation design

## Scope

The first inventory slice uses the existing `pos_stock_movements` and `pos_stock_lots` tables from schema v40. It does not create opening balances, invoices, ledger entries, or stock UI yet. The slice establishes an immutable movement aggregate, an exact weighted-average policy, and a repository port.

## Invariants

A movement stores a strictly positive `PosQuantity` plus an explicit direction. The data adapter maps incoming movements to a positive `quantity_scaled` and outgoing movements to a negative value. This keeps the domain quantity value object non-negative while preserving the signed SQL representation.

The movement type determines the normal direction: opening, purchase, sales return, and positive adjustment add stock; sale, purchase return, damage, expiry, and negative adjustment remove stock. Adjustment accepts an explicit direction so corrections are represented by a new append-only movement rather than updating an old movement.

A movement's product quantity scale must match the product's scale, and its unit cost must use the product currency and be non-negative. Product and warehouse IDs, source references, and idempotency keys are required. The repository must preserve the unique idempotency constraint and report a conflict rather than posting the same movement twice.

## Weighted-average policy

The balance is calculated by replaying movements in deterministic order (`occurred_at`, then `created_at`, then `id`). Incoming stock increases quantity and valuation by `quantity * unit cost`. Outgoing stock reduces quantity and valuation at the current weighted-average unit cost; it does not change the average cost. The average cost after an incoming movement is integer minor units rounded half-up from the exact integer numerator.

Negative on-hand is rejected by default. When an outgoing movement exceeds the available quantity, the policy returns a domain failure and the repository must not append the movement. No floating point values are used; multiplication, valuation, and rounding operate on integers.

## Transaction boundary

Application validates governance and invokes the policy against the current balance. The Data repository appends the immutable row inside a database transaction and relies on the unique idempotency key for replay safety. A later slice will add an atomic balance/locking strategy if concurrent writers require it; the current local-first Qayd process serializes database writes through SQLite transactions.
