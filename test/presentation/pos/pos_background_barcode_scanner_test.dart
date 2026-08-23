import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qayd/presentation/pos/pos_background_barcode_scanner.dart';

void main() {
  testWidgets('mounts scanner surface outside the visible sales UI',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PosBackgroundBarcodeScanner(
          enabled: false,
          onBarcode: (_) {},
        ),
      ),
    );
    await tester.pump();

    final surface = tester.widget<Opacity>(
      find.byKey(const ValueKey<String>('pos-background-scanner-surface')),
    );
    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));

    expect(surface.opacity, 0);
    expect(scanner.useAppLifecycleState, isFalse);
  });
}
