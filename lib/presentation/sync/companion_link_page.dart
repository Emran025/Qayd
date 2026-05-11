import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qayd/application/sync/companion_link_service.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/sync/manual_code_input_page.dart';
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
    // This can happen in Grace Window scenarios where the server returns the
    // same payload for a brief period after consumption.
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
  /// When the companion submits their keys, we get back a [CompanionLinkSession]
  /// and immediately hand it off to [_poll] by re-routing our existing polling.
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
    // Swap the current QR session for the manually-established one and
    // let the existing polling loop pick it up on its next tick.
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
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.linkAsCompanionDevice)),
      body: Center(
        child: (_busy && session == null)
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_timedOut) ...[
                      const Icon(Icons.timer_off_outlined,
                          size: 48, color: Colors.orange),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.companionCredentialsFailed,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _startSession,
                        icon: const Icon(Icons.refresh),
                        label: Text(AppStrings.regenerateQrCode),
                      ),
                    ] else if (_migrating) ...[
                      const SizedBox(height: 32),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        _migrationProgressText,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.migratingDataSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                    ] else ...[
                      Text(
                        AppStrings.scanCompanionQrInstruction,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (session != null)
                        QrImageView(data: session.qrPayload, size: 240),
                      const SizedBox(height: 12),
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _startSession,
                          icon: const Icon(Icons.refresh),
                          label: Text(AppStrings.retryAction),
                        ),
                      ],
                      // ── Manual Code option ──────────────────────────────
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.manualCodeDividerLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openManualCodeInput,
                        icon: const Icon(Icons.keyboard_rounded),
                        label: Text(AppStrings.manualCodeInputButton),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
