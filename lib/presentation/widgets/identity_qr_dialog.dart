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
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<String?>(
        future: _generateQrData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 300,
              width: 320,
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

          return ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 360,
              maxWidth: 420,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 260.0, // Slightly larger QR
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
                    child: Text(
                      AppStringsAr.qrCloseAction,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
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
