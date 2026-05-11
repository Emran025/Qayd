import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_qr_scanner.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

class DevicePairingQrScannerPage extends StatefulWidget {
  const DevicePairingQrScannerPage({super.key});

  @override
  State<DevicePairingQrScannerPage> createState() =>
      _DevicePairingQrScannerPageState();
}

class _DevicePairingQrScannerPageState extends State<DevicePairingQrScannerPage> {
  bool _found = false;

  @override
  Widget build(BuildContext context) {
    return QaydQrScanner(
      title: AppStrings.qrScannerTitle,
      hint: AppStrings.qrScannerHint,
      onDetect: (code) {
        if (_found) return;
        _found = true;
        Navigator.pop(context, code);
      },
    );
  }
}
