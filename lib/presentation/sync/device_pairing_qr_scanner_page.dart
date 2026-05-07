import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

class DevicePairingQrScannerPage extends StatefulWidget {
  const DevicePairingQrScannerPage({super.key});

  @override
  State<DevicePairingQrScannerPage> createState() =>
      _DevicePairingQrScannerPageState();
}

class _DevicePairingQrScannerPageState extends State<DevicePairingQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _found = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _hasPermission = status.isGranted;
    });
    if (!status.isGranted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.devicePairingScanQr)),
      body: _hasPermission
          ? MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_found) return;
                final code = capture.barcodes.first.rawValue;
                if (code != null && code.isNotEmpty) {
                  _found = true;
                  Navigator.pop(context, code);
                }
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
