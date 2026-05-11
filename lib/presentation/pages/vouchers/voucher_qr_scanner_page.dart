import 'package:flutter/material.dart';
import 'package:qayd/domain/services/voucher_qr_service.dart';
import 'package:qayd/presentation/components/atomic/qayd_qr_scanner.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

class VoucherQrScannerPage extends StatefulWidget {
  const VoucherQrScannerPage({super.key});

  @override
  State<VoucherQrScannerPage> createState() => _VoucherQrScannerPageState();
}

class _VoucherQrScannerPageState extends State<VoucherQrScannerPage> {
  bool _found = false;

  @override
  Widget build(BuildContext context) {
    return QaydQrScanner(
      title: AppStrings.qrScannerTitle,
      hint: AppStrings.qrScannerHint,
      onDetect: (code) {
        if (_found) return;

        const qrService = VoucherQrService();
        
        // 1. Check for P2P links
        if (qrService.isP2PLink(code)) {
          final p2p = qrService.parseP2PLink(code);
          if (p2p != null) {
            _found = true;
            Navigator.pop(context, {'p2p': p2p});
            return;
          }
        }

        // 2. Check for standard Voucher data
        final data = qrService.parseQrData(code);
        if (data != null) {
          _found = true;
          Navigator.pop(context, data);
        }
      },
    );
  }
}
