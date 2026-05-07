import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qayd/application/sync/companion_link_service.dart';
import 'package:qayd/di/injection_container.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final session =
        InjectionContainer.companionLinkService.startReceiverSession();
    setState(() {
      _session = session;
      _busy = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    final session = _session;
    if (session == null || _busy) return;
    try {
      final ok = await InjectionContainer.companionLinkService
          .pollAndConsumeBootstrap(session: session);
      if (!ok) return;
      _timer?.cancel();
      await widget.onProvisioningComplete();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Failed to receive companion credentials.');
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
      appBar: AppBar(title: const Text('Link as Companion Device')),
      body: Center(
        child: _busy
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Scan this QR from your main device to link instantly.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (session != null)
                      QrImageView(
                        data: session.qrPayload,
                        size: 240,
                      ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
