# POS Sales Posting Design

## Scope

This slice defines the accounting and inventory boundary for a POS sale. A sale remains a draft until explicitly posted. Posting must atomically persist the invoice snapshot, all invoice lines, outbound stock movements, the revenue/settlement accounting entries, and any initial payment events. A failure in any part rolls back the entire sale.

A posted sale is immutable. A later payment is a new payment event linked to the invoice. A return or correction is a new linked POS document and never edits the source invoice, stock movement, or ledger rows.

## Sale accounting

For a cash sale, the commercial journal is debit POS cash and credit POS sales revenue for the invoice total. For a credit sale, it is debit customer receivables and credit POS sales revenue. The inventory valuation journal is debit POS COGS and credit POS inventory for the exact weighted-average cost consumed by the outbound movements. Tax and discount mappings remain explicit template keys; missing required mappings fail before any write.

The sale coordinator must persist both journals through the official voucher/ledger adapter. It must not insert directly into `ledger_entries` from Application, Cubit, or Widgets.

## Exact totals

Quantities are `PosQuantity` scaled integers. Unit prices, unit costs, discounts, tax, paid, and due values are `Money` minor units. No `double` participates in validation, persistence, signatures, or replay fingerprints. Invoice lines store product name and barcode snapshots so historical PDFs remain stable after catalog changes.

## Fast checkout input

The checkout page has one canonical line-add command. Keyboard scanner input, manual barcode entry, camera detections, and advanced search all resolve through the same application use case. A repeated barcode detection within the debounce window increments the existing line quantity rather than adding an accidental duplicate. An unknown barcode becomes a searchable/manual-resolution state and never posts silently.

The camera capture surface is not visible in the sales composition. The scanner adapter owns permission, lifecycle, deduplication, and lens selection; the page only consumes typed barcode events. Because the selected `mobile_scanner` version has no documented headless API, a hidden mounted capture widget is acceptable only after Android/iOS device validation; otherwise a native headless adapter is required before claiming production readiness.

## Electronic signature

The signature payload is canonical and includes invoice ID/number, invoice date, document type, warehouse, counterparty, every line snapshot and exact amount, subtotal/discount/tax/total, payment summary, and due amount. It excludes mutable UI notes and audit timestamps. The resulting Ed25519 signature metadata is stored with the invoice and rendered in the PDF as signer identity, payload hash, and verification status. A signature is created only after the posted immutable snapshot is finalized.

## PDF/report output

Invoice and report generators reuse Qayd's Cairo font, header configuration, branding palette, RTL/LTR handling, and existing share-bytes path. A multi-page PDF must include line items, quantity, unit price, line total, invoice total, paid amount, due amount, counterparty, date, invoice number, and signature status. Reports use typed read DTOs and never query SQL from Widgets.

## Acceptance gates

The sale slice cannot be connected to the visible checkout UI until focused tests prove exact totals, governance and fiscal-period rejection before writes, missing template-account rejection, insufficient stock rollback, invoice/voucher/ledger rollback, payment idempotency, exact replay without ledger mutation, signature verification, and stable PDF snapshot content. Camera behavior additionally requires real-device Android/iOS validation because the sandbox cannot provide physical camera hardware.
