import 'package:flutter/material.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/services/receipt_sharing_service.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qayd/domain/services/voucher_qr_service.dart';
import 'package:qayd/presentation/components/atomic/qayd_dialog.dart';

class ReceiptShareSheet extends StatelessWidget {
  const ReceiptShareSheet({
    super.key,
    required this.receipt,
    required this.sharingService,
    required this.qrService,
    this.ownerPhone,
  });

  final Voucher receipt;
  final ReceiptSharingService sharingService;
  final VoucherQrService qrService;
  final String? ownerPhone;

  static void show(
    BuildContext context, {
    required Voucher receipt,
    required ReceiptSharingService sharingService,
    required VoucherQrService qrService,
    String? ownerPhone,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReceiptShareSheet(
        receipt: receipt,
        sharingService: sharingService,
        qrService: qrService,
        ownerPhone: ownerPhone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = qrService.generateQrData(receipt, ownerPhone);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              AppStringsAr.shareReceiptTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(),
          _buildShareOption(
            context,
            icon: Icons.qr_code,
            label: AppStringsAr.shareAsQr,
            title: AppStringsAr.qrCodeDisplayTitle,
            onTap: () {
              Navigator.of(context).pop();
              _showQrCodeDialog(context, qrData, theme);
            },
          ),
          _buildShareOption(
            context,
            icon: Icons.sms,
            label: AppStringsAr.shareAsSms,
            title: AppStringsAr.shareAsSms,
            onTap: () async {
              Navigator.of(context).pop();
              await sharingService.shareAsSms(receipt);
            },
          ),
          _buildShareOption(
            context,
            icon: Icons.chat,
            label: AppStringsAr.shareViaWhatsApp,
            title: AppStringsAr.shareViaWhatsApp,
            onTap: () async {
              Navigator.of(context).pop();
              await sharingService.shareViaWhatsApp(receipt);
            },
          ),
          _buildShareOption(
            context,
            icon: Icons.picture_as_pdf,
            label: AppStringsAr.shareAsPdf,
            title: AppStringsAr.shareAsPdf,
            onTap: () async {
              Navigator.of(context).pop();
              await sharingService.shareAsPdf(receipt);
            },
          ),
          _buildShareOption(
            context,
            icon: Icons.image,
            label: AppStringsAr.shareAsImage,
            title: AppStringsAr.shareAsImage,
            onTap: () async {
              Navigator.of(context).pop();
              await sharingService.shareAsImage(receipt);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      onTap: onTap,
    );
  }

  void _showQrCodeDialog(BuildContext context, String qrData, ThemeData theme) {
    QaydDialog.show(
      context: context,
      icon: Icons.qr_code_rounded,
      title: AppStringsAr.qrCodeDisplayTitle,
      content: Center(
        child: SizedBox(
          width: 250,
          height: 250,
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 250.0,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: theme.colorScheme.primary,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
      primaryActionLabel: AppStringsAr.closing1,
      onPrimaryAction: () => Navigator.pop(context),
    );
  }
}
