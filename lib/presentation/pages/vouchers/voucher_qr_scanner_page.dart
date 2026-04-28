import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qayd/domain/services/voucher_qr_service.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';

class VoucherQrScannerPage extends StatefulWidget {
  const VoucherQrScannerPage({super.key});

  @override
  State<VoucherQrScannerPage> createState() => _VoucherQrScannerPageState();
}

class _VoucherQrScannerPageState extends State<VoucherQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _found = false;

  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied || status.isDenied) {
      if (mounted) {
        _showPermissionDialog();
      }
    } else {
      if (mounted) {
        setState(() {
          _hasPermission = true;
        });
      }
    }
  }

  void _showPermissionDialog() {
    QaydDialog.show(
      context: context,
      icon: Icons.shield_rounded,
      title: AppStringsAr.permissionCameraMissingTitle,
      content: AppStringsAr.permissionCameraMissingBodyQr,
      secondaryActionLabel: AppStringsAr.actionCancel,
      onSecondaryAction: () {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Go back
      },
      primaryActionLabel: AppStringsAr.actionOpenSettings,
      onPrimaryAction: () {
        Navigator.pop(context); // Close dialog
        openAppSettings();
        Navigator.pop(context); // Go back
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          AppStringsAr.qrScannerTitle,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_hasPermission)
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_found) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final code = barcode.rawValue;
                  if (code != null) {
                    const qrService = VoucherQrService();
                    if (qrService.isP2PLink(code)) {
                      final p2p = qrService.parseP2PLink(code);
                      if (p2p != null) {
                        setState(() => _found = true);
                        Navigator.pop(context, {'p2p': p2p});
                        return;
                      }
                    }

                    final data = qrService.parseQrData(code);
                    if (data != null) {
                      setState(() => _found = true);
                      Navigator.pop(context, data);
                      return;
                    }
                  }
                }
              },
            ),
          _buildOverlay(),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  AppStringsAr.qrScannerHint,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.7;
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF38BDF8), width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }
}
