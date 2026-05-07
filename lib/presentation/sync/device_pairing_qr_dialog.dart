import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

class DevicePairingQrDialog extends StatelessWidget {
  const DevicePairingQrDialog({super.key, required this.qrPayload});

  final String qrPayload;

  static Future<void> show(
    BuildContext context, {
    required String qrPayload,
  }) {
    return showDialog(
      context: context,
      builder: (_) => DevicePairingQrDialog(qrPayload: qrPayload),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.devicePairingDialogTitle,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 240,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.qrCloseAction),
            ),
          ],
        ),
      ),
    );
  }
}
