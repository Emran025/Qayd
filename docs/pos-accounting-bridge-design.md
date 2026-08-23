# POS Accounting Bridge Design

## Objective

The POS accounting bridge must connect a posted POS document or opening-stock movement to Qayd's existing voucher and ledger workflow without creating a parallel ledger writer. It must remain inside the shared Flutter application, SQLCipher database, identity, governance rules, and fiscal-period policy.

## Existing official path

Qayd already exposes `VoucherRepository.saveWithLedgerEntries`, which persists a voucher and its generated ledger lines in one transaction. `EntryGenerator` builds the canonical two-line receipt/payment entries from a confirmed `Voucher`. `CreateVoucherUseCase` performs governance and fiscal-period checks before saving a voucher. POS must reuse or extend these official ports rather than inserting into `ledger_entries` directly.

## Required POS bridge boundary

The bridge should be an Application-level orchestration use case. Its input is a typed POS posting command containing the source POS document ID, posting date, base currency, total amount, account mapping keys, and an idempotency key. It must first pass `GovernanceWriteGuard`, then apply `FiscalPeriodPolicy` to the posting date, resolve the activated POS template account IDs by metadata key, construct a confirmed domain `Voucher`, generate balanced `LedgerEntry` values through the approved generator or a POS-specific domain generator, and delegate persistence to `VoucherRepository.saveWithLedgerEntries`.

The Data layer remains responsible for persistence adapters and transaction implementation. No Widget, Cubit, POS repository, or stock movement adapter may issue SQL against `ledger_entries`. Any SDK or existing accounting implementation must remain behind a repository or adapter port.

## Document-to-entry mapping

| POS event | Debit | Credit | Inventory effect |
|---|---|---|---|
| Opening stock | POS inventory asset | POS opening-balance clearing/equity account | Inbound at supplied cost |
| Purchase, cash | POS inventory asset | POS cash | Inbound at purchase cost |
| Purchase, credit | POS inventory asset | Supplier payable | Inbound at purchase cost |
| Sale, cash | POS cash | POS sales revenue | Outbound at weighted-average cost; separate COGS pair required |
| Sale, credit | Customer receivable | POS sales revenue | Outbound at weighted-average cost; separate COGS pair required |
| Sales return | POS sales returns and inventory asset as applicable | Customer/cash and COGS reversal as applicable | Inbound at the approved return-cost policy |
| Purchase return | Supplier payable/cash and purchase-returns account as applicable | POS inventory asset | Outbound at the original or approved return-cost policy |

A sale or purchase cannot be considered posted when only the revenue/payment pair exists while the inventory and COGS effects are absent. The final implementation must represent the complete balanced journal, not a partial convenience entry.

## Identified prerequisite

The current POS template contains inventory, revenue, COGS, cash, receivables, payables, returns, discounts, and optional tax accounts, but it does not contain an explicit opening-balance clearing/equity account. The opening-balance accounting bridge must not silently use an unrelated account. Before posting opening stock to the ledger, the template must gain a stable `openingBalanceClearing` account key under a versioned template upgrade, or the product must explicitly select an existing authorized counterpart account through a typed configuration use case. The choice must be persisted by metadata key, not by account name.

## Fiscal-period and correction rules

Posting dates in closed fiscal periods must be rejected before any voucher, ledger, or stock write. A correction must be a new reversal or corrective document linked to the source document; neither the voucher nor ledger rows may be updated to rewrite history. The bridge must reject duplicate source/idempotency keys deterministically and return the existing posting only when its immutable fingerprint matches.

## Atomicity requirement

Stock movement and accounting posting must eventually share one atomic application/data boundary for a posted purchase, sale, return, or opening balance. The current `VoucherRepository.saveWithLedgerEntries` transaction covers voucher plus ledger lines, while the stock repository transaction covers stock movement plus weighted-average validation. A future cross-repository transaction coordinator is required before invoices are enabled; invoking the two repositories sequentially is not sufficient for a production posting path because a failure between them could leave inventory and accounting inconsistent.

## Implementation order

1. Add and version the missing opening-balance account mapping, or explicitly defer ledger posting for opening stock until that mapping exists.
2. Define typed account-key resolution and POS posting command/result ports in Domain/Application.
3. Implement a bridge that delegates voucher persistence and ledger generation through official repositories.
4. Add a transaction coordinator/adapter capable of committing stock and voucher-ledger effects together, with idempotency and rollback tests.
5. Only after these gates pass, enable posted purchase/sale documents and checkout UI.
