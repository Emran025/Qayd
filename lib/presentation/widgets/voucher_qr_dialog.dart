import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class VoucherQrDialog extends StatelessWidget {
  const VoucherQrDialog({
    super.key,
    required this.qrData,
    required this.voucherDescription,
    required this.amountLabel,
  });

  final String qrData;
  final String voucherDescription;
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B), // Navy800
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QaydText(
              AppStringsAr.qrCodeDisplayTitle,
              slot: QaydTextStyleSlot.titleMedium,
              color: Colors.white,
            ),
            const SizedBox(height: SpacingTokens.lg),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: ColorTokens.navy900,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: ColorTokens.navy900,
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            QaydText(
              amountLabel,
              slot: QaydTextStyleSlot.titleLarge,
              color: const Color(0xFF38BDF8),
            ),
            if (voucherDescription.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.xs),
              QaydText(
                voucherDescription,
                slot: QaydTextStyleSlot.bodyMedium,
                color: Colors.white.withOpacity(0.7),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: SpacingTokens.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStringsAr.qrCloseAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
