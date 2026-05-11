import 'package:flutter/material.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/atomic/qayd_qr_scanner.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

class CounterpartyQrScannerPage extends StatefulWidget {
  const CounterpartyQrScannerPage({super.key});

  @override
  State<CounterpartyQrScannerPage> createState() =>
      _CounterpartyQrScannerPageState();
}

class _CounterpartyQrScannerPageState extends State<CounterpartyQrScannerPage> {
  bool _found = false;

  @override
  Widget build(BuildContext context) {
    return QaydQrScanner(
      title: AppStrings.identityQrScanTitle,
      hint: AppStrings.identityQrScanHint,
      onDetect: (code) {
        if (_found) return;

        final data = InjectionContainer.counterpartyQrService.parseAccountQr(code);
        if (data != null) {
          _found = true;
          Navigator.pop(context, data);
        }
      },
    );
  }
}
