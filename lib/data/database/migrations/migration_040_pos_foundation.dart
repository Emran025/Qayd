import 'package:qayd/data/database/migrations/schema_migration.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Schema v40: POS operational foundation only.
///
/// This migration creates structure and constraints. It intentionally does not
/// insert POS accounts, classifications, warehouses, or settings. Those records
/// are installed by the explicit POS activation use case after user opt-in.
final class Migration040PosFoundation implements SchemaMigration {
  @override
  int get version => 40;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        is_enabled INTEGER NOT NULL DEFAULT 0 CHECK (is_enabled IN (0, 1)),
        template_key TEXT,
        template_version INTEGER,
        warehouse_id TEXT,
        cost_method TEXT NOT NULL DEFAULT 'weighted_average'
          CHECK (cost_method IN ('weighted_average')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (warehouse_id) REFERENCES pos_warehouses (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_template_installs (
        id TEXT PRIMARY KEY,
        template_key TEXT NOT NULL,
        template_version INTEGER NOT NULL CHECK (template_version > 0),
        status TEXT NOT NULL CHECK (status IN ('installing', 'installed', 'failed')),
        account_map_json TEXT,
        installed_at TEXT,
        installed_by_device TEXT,
        last_error_code TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE (template_key, template_version)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_warehouses (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0, 1)),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_pos_one_default_warehouse
      ON pos_warehouses (is_default) WHERE is_default = 1
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_products (
        id TEXT PRIMARY KEY,
        sku TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        unit_name TEXT NOT NULL DEFAULT 'unit',
        currency_code TEXT NOT NULL,
        sale_price_minor INTEGER NOT NULL CHECK (sale_price_minor >= 0),
        purchase_price_minor INTEGER NOT NULL CHECK (purchase_price_minor >= 0),
        quantity_scale INTEGER NOT NULL DEFAULT 0 CHECK (quantity_scale BETWEEN 0 AND 6),
        reorder_level_scaled INTEGER NOT NULL DEFAULT 0 CHECK (reorder_level_scaled >= 0),
        expiry_tracking INTEGER NOT NULL DEFAULT 0 CHECK (expiry_tracking IN (0, 1)),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_product_barcodes (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        barcode TEXT NOT NULL UNIQUE,
        symbology TEXT,
        is_primary INTEGER NOT NULL DEFAULT 0 CHECK (is_primary IN (0, 1)),
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES pos_products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_pos_primary_barcode
      ON pos_product_barcodes (product_id) WHERE is_primary = 1
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_stock_lots (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        warehouse_id TEXT NOT NULL,
        lot_number TEXT,
        expiry_date TEXT,
        received_quantity_scaled INTEGER NOT NULL CHECK (received_quantity_scaled > 0),
        remaining_quantity_scaled INTEGER NOT NULL CHECK (remaining_quantity_scaled >= 0),
        quantity_scale INTEGER NOT NULL CHECK (quantity_scale BETWEEN 0 AND 6),
        unit_cost_minor INTEGER NOT NULL CHECK (unit_cost_minor >= 0),
        currency_code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES pos_products (id),
        FOREIGN KEY (warehouse_id) REFERENCES pos_warehouses (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        warehouse_id TEXT NOT NULL,
        movement_type TEXT NOT NULL CHECK (
          movement_type IN (
            'opening', 'purchase', 'sale', 'sales_return',
            'purchase_return', 'adjustment', 'damage', 'expiry'
          )
        ),
        quantity_scaled INTEGER NOT NULL CHECK (quantity_scaled <> 0),
        quantity_scale INTEGER NOT NULL CHECK (quantity_scale BETWEEN 0 AND 6),
        unit_cost_minor INTEGER NOT NULL CHECK (unit_cost_minor >= 0),
        currency_code TEXT NOT NULL,
        source_type TEXT,
        source_id TEXT,
        source_line_id TEXT,
        lot_id TEXT,
        occurred_at TEXT NOT NULL,
        idempotency_key TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES pos_products (id),
        FOREIGN KEY (warehouse_id) REFERENCES pos_warehouses (id),
        FOREIGN KEY (lot_id) REFERENCES pos_stock_lots (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_invoices (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        document_type TEXT NOT NULL CHECK (
          document_type IN ('sale', 'purchase', 'sales_return', 'purchase_return')
        ),
        status TEXT NOT NULL CHECK (
          status IN (
            'draft', 'posted', 'partiallyPaid', 'paid',
            'partiallyReturned', 'fullyReturned', 'voided'
          )
        ),
        counterparty_account_id TEXT,
        warehouse_id TEXT NOT NULL,
        source_invoice_id TEXT,
        currency_code TEXT NOT NULL,
        subtotal_minor INTEGER NOT NULL CHECK (subtotal_minor >= 0),
        discount_minor INTEGER NOT NULL DEFAULT 0 CHECK (discount_minor >= 0),
        tax_minor INTEGER NOT NULL DEFAULT 0 CHECK (tax_minor >= 0),
        total_minor INTEGER NOT NULL CHECK (total_minor >= 0),
        paid_minor INTEGER NOT NULL DEFAULT 0 CHECK (paid_minor >= 0),
        due_minor INTEGER NOT NULL DEFAULT 0 CHECK (due_minor >= 0),
        idempotency_key TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        posted_at TEXT,
        FOREIGN KEY (counterparty_account_id) REFERENCES accounts (id),
        FOREIGN KEY (warehouse_id) REFERENCES pos_warehouses (id),
        FOREIGN KEY (source_invoice_id) REFERENCES pos_invoices (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_invoice_lines (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name_snapshot TEXT NOT NULL,
        barcode_snapshot TEXT,
        quantity_scaled INTEGER NOT NULL CHECK (quantity_scaled > 0),
        quantity_scale INTEGER NOT NULL CHECK (quantity_scale BETWEEN 0 AND 6),
        unit_price_minor INTEGER NOT NULL CHECK (unit_price_minor >= 0),
        unit_cost_minor INTEGER NOT NULL CHECK (unit_cost_minor >= 0),
        discount_minor INTEGER NOT NULL DEFAULT 0 CHECK (discount_minor >= 0),
        tax_minor INTEGER NOT NULL DEFAULT 0 CHECK (tax_minor >= 0),
        line_total_minor INTEGER NOT NULL CHECK (line_total_minor >= 0),
        source_line_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES pos_invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES pos_products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_payments (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        payment_method TEXT NOT NULL CHECK (
          payment_method IN ('cash', 'bank', 'credit', 'other')
        ),
        amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
        currency_code TEXT NOT NULL,
        occurred_at TEXT NOT NULL,
        idempotency_key TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES pos_invoices (id),
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_returns (
        id TEXT PRIMARY KEY,
        source_invoice_id TEXT NOT NULL,
        return_invoice_id TEXT NOT NULL UNIQUE,
        reason TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (source_invoice_id) REFERENCES pos_invoices (id),
        FOREIGN KEY (return_invoice_id) REFERENCES pos_invoices (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_document_sequences (
        scope TEXT PRIMARY KEY,
        prefix TEXT NOT NULL,
        next_number INTEGER NOT NULL CHECK (next_number > 0),
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pos_barcodes_product ON pos_product_barcodes (product_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pos_products_active_name ON pos_products (is_active, name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pos_stock_product_warehouse ON pos_stock_movements (product_id, warehouse_id, occurred_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pos_stock_expiry ON pos_stock_lots (expiry_date, remaining_quantity_scaled)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pos_invoices_date_status ON pos_invoices (created_at, status, document_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pos_invoices_counterparty ON pos_invoices (counterparty_account_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pos_invoice_lines_product ON pos_invoice_lines (product_id, invoice_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pos_payments_invoice ON pos_payments (invoice_id, occurred_at)',
    );
  }
}
