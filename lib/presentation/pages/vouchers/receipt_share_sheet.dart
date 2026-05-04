import 'package:flutter/material.dart';
import 'package:qayd/domain/entities/collateral.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/services/receipt_sharing_service.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
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
    this.collateral,
  });

  final Voucher receipt;
  final ReceiptSharingService sharingService;
  final VoucherQrService qrService;
  final String? ownerPhone;
  final Collateral? collateral;

  static void show(
    BuildContext context, {
    required Voucher receipt,
    required ReceiptSharingService sharingService,
    required VoucherQrService qrService,
    String? ownerPhone,
    Collateral? collateral,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReceiptShareSheet(
        receipt: receipt,
        sharingService: sharingService,
        qrService: qrService,
        ownerPhone: ownerPhone,
        collateral: collateral,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = qrService.generateQrData(
      receipt,
      ownerPhone: ownerPhone,
      collateral: collateral,
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              AppStrings.shareReceiptTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(),
          _buildShareOption(
            context,
            icon: Icons.qr_code,
            label: AppStrings.shareAsQr,
            title: AppStrings.qrCodeDisplayTitle,
            onTap: () {
              Navigator.of(context).pop();
              _showQrCodeDialog(context, qrData, theme);
            },
          ),
          _buildShareOption(
            context,
            icon: Icons.sms,
            label: AppStrings.shareAsSms,
            title: AppStrings.shareAsSms,
            onTap: () async {
              Navigator.of(context).pop();
              await sharingService.shareAsSms(receipt);
            },
          ),
          _buildShareOption(
            context,
            icon: Icons.chat,
            label: AppStrings.shareViaWhatsApp,
            title: AppStrings.shareViaWhatsApp,
            onTap: () async {
              Navigator.of(context).pop();
              await sharingService.shareViaWhatsApp(receipt);
            },
          ),
          _buildShareOption(
            context,
            icon: Icons.picture_as_pdf,
            label: AppStrings.shareAsPdf,
            title: AppStrings.shareAsPdf,
            onTap: () async {
              Navigator.of(context).pop();
              await sharingService.shareAsPdf(receipt);
            },
          ),
          _buildShareOption(
            context,
            icon: Icons.image,
            label: AppStrings.shareAsImage,
            title: AppStrings.shareAsImage,
            onTap: () async {
              Navigator.of(context).pop();
              await sharingService.shareAsImage(receipt);
            },
          ),
          SizedBox(height: 16),
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
      title: AppStrings.qrCodeDisplayTitle,
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
      primaryActionLabel: AppStrings.closing1,
      onPrimaryAction: () => Navigator.pop(context),
    );
  }
}
