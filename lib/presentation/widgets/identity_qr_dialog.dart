import 'package:flutter/material.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class IdentityQrDialog extends StatelessWidget {
  const IdentityQrDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const IdentityQrDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gold = theme.extension<QaydCustomColors>()!.goldAccent;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: FutureBuilder<String?>(
        future: _generateQrData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final qrData = snapshot.data;
          if (qrData == null) {
            return Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Text(AppStringsAr.identityNotSetup),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SpacingTokens.lg,
                  SpacingTokens.lg,
                  SpacingTokens.lg,
                  SpacingTokens.sm,
                ),
                child: Text(
                  AppStringsAr.identityQrShowTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: gold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
                child: Text(
                  AppStringsAr.identityQrShowSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: SpacingTokens.md),
              Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 240.0,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: scheme.primary,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: SpacingTokens.lg),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SpacingTokens.md,
                  0,
                  SpacingTokens.md,
                  SpacingTokens.md,
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStringsAr.qrCloseAction),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _generateQrData() async {
    final license = await InjectionContainer.licenseVault.readLicenseData();
    if (license == null) return null;

    final keyPair = await InjectionContainer.setupIdentityUseCase.getKeyPair();
    if (keyPair == null) return null;

    // Use current profile data from license vault
    return InjectionContainer.counterpartyQrService.generateAccountQr(
      name: license['name'] ?? '',
      phone: license['phone'] ?? '',
      email: license['email'] ?? '',
      currentPublicKeyHex: keyPair.publicKeyHex,
      publicKeyHistoryHex: [], // History not currently cached locally for the owner
      serverAccountId: license['id'] as int?,
    );
  }
}
