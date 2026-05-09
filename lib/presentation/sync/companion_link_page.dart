import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qayd/application/sync/companion_link_service.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
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
  bool _bootstrapHandled = false;  // Guards against double-processing.
  String? _error;

  // Poll every 5 seconds, max 120 attempts (10 minutes total).
  static const _pollInterval = Duration(seconds: 5);
  static const _maxAttempts = 120;
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
    if (session == null || _busy) return;

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
      final ok = await InjectionContainer.companionLinkService
          .pollAndConsumeBootstrap(session: session);

      if (!ok) {
        // No bootstrap yet — keep waiting silently.
        if (mounted) setState(() => _busy = false);
        return;
      }

      // Bootstrap consumed successfully — stop polling immediately.
      _bootstrapHandled = true;
      _timer?.cancel();
      await widget.onProvisioningComplete();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppStrings.companionCredentialsFailed;
          _busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                        label: const Text('إعادة توليد رمز QR'),
                      ),
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
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
