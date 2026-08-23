import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/pdf/cairo_pos_invoice_pdf_generator.dart';
import 'package:qayd/domain/entities/pos_invoice.dart';
import 'package:qayd/domain/entities/pos_sales_report.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/pos_quantity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const currency = CurrencyCode(
    code: 'YER',
    nameAr: 'ريال يمني',
    symbol: 'ر.ي',
    fractionalDigits: 2,
  );

  PosInvoice buildInvoice() {
    final line = PosInvoiceLine.create(
      id: 'line-1',
      invoiceId: 'invoice-1',
      productId: 'product-1',
      productNameSnapshot: 'Coffee',
      barcodeSnapshot: '629000000001',
      quantity: PosQuantity.fromScaled(1250, scale: 3),
      unitPrice: Money.fromMinorUnits(400, currency),
      unitCost: Money.fromMinorUnits(250, currency),
      discount: Money.zero(currency),
      tax: Money.zero(currency),
      createdAt: DateTime.utc(2026, 1, 1, 10),
    );
    return PosInvoice.draft(
      id: 'invoice-1',
      invoiceNumber: 'S-000001',
      type: PosInvoiceType.sale,
      warehouseId: 'warehouse-1',
      currency: currency,
      lines: [line],
      idempotencyKey: 'sale:invoice-1',
      invoiceDate: DateTime.utc(2026, 1, 1, 10),
      now: DateTime.utc(2026, 1, 1, 10),
    ).post(DateTime.utc(2026, 1, 1, 10, 1)).applyPayment(
          Money.fromMinorUnits(200, currency),
          DateTime.utc(2026, 1, 1, 10, 2),
        );
  }

  test('renders invoice with exact fractional quantity and payment totals',
      () async {
    final result = await const CairoPosInvoicePdfGenerator()
        .buildInvoicePdf(buildInvoice());

    expect(result, isA<Success<Uint8List>>(),
        reason: result.failureOrNull?.messageAr);
    expect(result.valueOrNull, isNotNull);
    expect(result.valueOrNull!.length, greaterThan(500));
  });

  test('renders a multi-invoice sales report with paid and due summaries',
      () async {
    final invoice = buildInvoice();
    final report = PosSalesReport(
      from: DateTime.utc(2026, 1, 1),
      to: DateTime.utc(2026, 1, 31),
      currency: currency,
      invoices: [invoice],
    );

    expect(report.grossTotal.minorUnits, 500);
    expect(report.paidTotal.minorUnits, 200);
    expect(report.dueTotal.minorUnits, 300);

    final result =
        await const CairoPosInvoicePdfGenerator().buildSalesReportPdf(report);
    expect(result, isA<Success<Uint8List>>(),
        reason: result.failureOrNull?.messageAr);
    expect(result.valueOrNull, isNotNull);
    expect(result.valueOrNull!.length, greaterThan(500));
  });
}
