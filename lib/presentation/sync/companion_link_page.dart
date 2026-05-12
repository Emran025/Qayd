import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qayd/application/sync/companion_link_service.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/components/auth/auth_animated_icon.dart';
import 'package:qayd/presentation/components/auth/auth_gradient_scaffold.dart';
import 'package:qayd/presentation/components/auth/auth_submit_button.dart';
import 'package:qayd/presentation/components/auth/auth_title_block.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/sync/manual_code_input_page.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CompanionLinkPage extends StatefulWidget {
  const CompanionLinkPage({
    super.key,
    required this.onProvisioningComplete,
  });

  final Future<void> Function() onProvisioningComplete;

  @override
  State<CompanionLinkPage> createState() => _CompanionLinkPageState();
}

class _CompanionLinkPageState extends State<CompanionLinkPage> {
  CompanionLinkSession? _session;
  Timer? _timer;
  bool _busy = true;
  bool _timedOut = false;
  bool _bootstrapHandled = false; // Guards against double-processing.
  bool _migrating = false; // Show migration progress when payload is received
  String _migrationProgressText = AppStrings.migratingData;
  String? _error;

  // Poll every 10 seconds, max 12 attempts (2 minute total).
  static const _pollInterval = Duration(seconds: 10);
  static const _maxAttempts = 12;
  int _attemptCount = 0;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  /// Generates a fresh session QR and starts the polling loop.
  /// Always creates a brand-new session — never reuses a stale one.
  Future<void> _startSession() async {
    _timer?.cancel();
    setState(() {
      _busy = true;
      _error = null;
      _timedOut = false;
      _bootstrapHandled = false;
      _migrating = false;
      _attemptCount = 0;
      _session = null;
    });

    final session =
        InjectionContainer.companionLinkService.startReceiverSession();

    if (!mounted) return;
    setState(() {
      _session = session;
      _busy = false;
    });

    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    final session = _session;
    if (session == null || _busy || _migrating) return;

    // Guard against the Timer firing a second time before cancel() takes effect.
    if (_bootstrapHandled) return;

    // Hard timeout guard — stop polling if Primary never scans within window.
    _attemptCount++;
    if (_attemptCount >= _maxAttempts) {
      _timer?.cancel();
      if (mounted) setState(() => _timedOut = true);
      return;
    }

    if (mounted) setState(() => _busy = true);

    try {
      final ok =
          await InjectionContainer.companionLinkService.pollAndConsumeBootstrap(
        session: session,
        onPayloadReceived: () {
          if (mounted) {
            setState(() {
              _migrating = true;
            });
          }
        },
      );

      if (!ok) {
        // No bootstrap yet — keep waiting silently.
        if (mounted) setState(() => _busy = false);
        return;
      }

      // Bootstrap consumed successfully — stop polling the QR endpoint.
      _bootstrapHandled = true;
      _timer?.cancel();

      // Initialize and open the database while the migrating UI is still visible
      await widget.onProvisioningComplete();

      // Now that the DB is open, register the primary device as a trusted peer
      final licenseData =
          await InjectionContainer.licenseVault.readLicenseData();
      if (licenseData != null) {
        await InjectionContainer.setupIdentityUseCase
            .trustPrimaryIdentity(licenseData);
      }

      // Wait for the full initial snapshot to be downloaded via standard sync mechanism.
      bool isComplete =
          await InjectionContainer.licenseVault.isInitialSyncComplete();
      int maxMigrationWait =
          60; // 60 iterations * 2 seconds = 2 minutes max wait

      while (!isComplete && maxMigrationWait > 0) {
        if (!mounted) return;
        await InjectionContainer.syncCoordinatorService.forceSync();
        await Future.delayed(const Duration(seconds: 2));

        final progress =
            await InjectionContainer.licenseVault.readInitialSyncProgress();
        if (mounted && progress != null) {
          setState(() {
            _migrationProgressText =
                AppStrings.migratingFinancialLedger(progress);
          });
        }

        isComplete =
            await InjectionContainer.licenseVault.isInitialSyncComplete();
        maxMigrationWait--;
      }

      // Add a slight delay for smooth UX transition (preventing UI flicker)
      await Future.delayed(const Duration(milliseconds: 1500));

      // Finish and return
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppStrings.companionCredentialsFailed;
          _busy = false;
          _migrating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Opens the manual code input screen.
  Future<void> _openManualCodeInput() async {
    if (!mounted) return;
    final CompanionLinkSession? session =
        await Navigator.of(context).push<CompanionLinkSession>(
      MaterialPageRoute(
        builder: (_) => ManualCodeInputPage(
          onSessionReady: (s) => Navigator.of(context).pop(s),
        ),
      ),
    );
    if (session == null || !mounted) return;
    _timer?.cancel();
    setState(() {
      _session = session;
      _busy = false;
      _timedOut = false;
      _bootstrapHandled = false;
      _migrating = false;
      _attemptCount = 0;
    });
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return AuthGradientScaffold(
      child: SafeArea(
        child: Stack(
          children: [
            // Main Centered Content
            Positioned.fill(
              child: (_busy && session == null)
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: SpacingTokens.lg),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  // Extra spacing at top
                                  const SizedBox(height: 60),

                                  if (_timedOut) ...[
                                    AuthAnimatedIcon(
                                      iconData: Icons.timer_off_outlined,
                                      iconColor: ColorTokens.errorSoft,
                                    ),
                                    const SizedBox(height: SpacingTokens.lg),
                                    AuthTitleBlock(
                                      title: AppStrings.linkAsCompanionDevice,
                                      subtitle: AppStrings
                                          .companionCredentialsFailed,
                                    ),
                                    const SizedBox(height: SpacingTokens.xl),
                                    AuthSubmitButton(
                                      label: AppStrings.regenerateQrCode,
                                      onPressed: () => _startSession(),
                                    ),
                                  ] else if (_migrating) ...[
                                    const AuthAnimatedIcon(
                                      iconData: Icons.cloud_download_rounded,
                                      iconColor: ColorTokens.emerald500,
                                    ),
                                    const SizedBox(height: SpacingTokens.lg),
                                    AuthTitleBlock(
                                      title: AppStrings.linkAsCompanionDevice,
                                      subtitle: _migrationProgressText,
                                    ),
                                    const SizedBox(height: SpacingTokens.md),
                                    Text(
                                      AppStrings.migratingDataSubtitle,
                                      style: const TextStyle(
                                          color: ColorTokens.slate400,
                                          fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 40),
                                    const LinearProgressIndicator(
                                      backgroundColor: ColorTokens.slate800,
                                      color: ColorTokens.emerald500,
                                    ),
                                  ] else ...[
                                    const AuthAnimatedIcon(
                                      iconData: Icons.qr_code_scanner_rounded,
                                      iconColor: ColorTokens.emerald500,
                                    ),
                                    const SizedBox(height: SpacingTokens.lg),
                                    AuthTitleBlock(
                                      title: AppStrings.linkAsCompanionDevice,
                                      subtitle: AppStrings
                                          .scanCompanionQrInstruction,
                                    ),
                                    const SizedBox(height: SpacingTokens.xl),
                                    if (session != null)
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.1),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: QrImageView(
                                          data: session.qrPayload,
                                          size: 200,
                                          eyeStyle: const QrEyeStyle(
                                            eyeShape: QrEyeShape.square,
                                            color: ColorTokens.navy950,
                                          ),
                                          dataModuleStyle:
                                              const QrDataModuleStyle(
                                            dataModuleShape:
                                                QrDataModuleShape.square,
                                            color: ColorTokens.navy950,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 24),
                                    if (_busy)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 40),
                                        child: LinearProgressIndicator(
                                          backgroundColor: ColorTokens.slate800,
                                          color: ColorTokens.emerald500,
                                        ),
                                      ),
                                    if (_error != null) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        _error!,
                                        style: const TextStyle(
                                            color: ColorTokens.errorSoft,
                                            fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton.icon(
                                        onPressed: () => _startSession(),
                                        icon: const Icon(Icons.refresh,
                                            size: 18),
                                        label: Text(AppStrings.retryAction),
                                        style: TextButton.styleFrom(
                                            foregroundColor:
                                                ColorTokens.emerald400),
                                      ),
                                    ],
                                    const SizedBox(height: 32),
                                    const Divider(color: ColorTokens.slate800),
                                    const SizedBox(height: 24),
                                    Text(
                                      AppStrings.manualCodeDividerLabel,
                                      style: const TextStyle(
                                          color: ColorTokens.slate400,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 16),
                                    AuthSubmitButton(
                                      label: AppStrings.manualCodeInputButton,
                                      onPressed: () => _openManualCodeInput(),
                                      color: ColorTokens.slate800,
                                    ),
                                  ],

                                  // Spacing at bottom
                                  const SizedBox(height: 60),
                                ],
                              ),
                            ),
                          );
                      },
                    ),
            ),

            // Back Button (Overlaid)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: ColorTokens.slate400, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
