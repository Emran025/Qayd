import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Invisible camera capture surface for POS checkout.
///
/// The widget is mounted at 1x1 logical pixels and fully transparent, so the
/// sales page never displays a camera preview. It owns only camera lifecycle,
/// permission/error forwarding, and duplicate-event suppression. Product
/// resolution and invoice business rules stay outside this widget.
class PosBackgroundBarcodeScanner extends StatefulWidget {
  const PosBackgroundBarcodeScanner({
    super.key,
    required this.onBarcode,
    this.onError,
    this.enabled = true,
    this.debounce = const Duration(milliseconds: 700),
  });

  final ValueChanged<String> onBarcode;
  final ValueChanged<Object>? onError;
  final bool enabled;
  final Duration debounce;

  @override
  PosBackgroundBarcodeScannerState createState() =>
      PosBackgroundBarcodeScannerState();
}

class PosBackgroundBarcodeScannerState
    extends State<PosBackgroundBarcodeScanner> with WidgetsBindingObserver {
  late final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const <BarcodeFormat>[
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.itf14,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.qrCode,
    ],
  );

  StreamSubscription<BarcodeCapture>? _subscription;
  String? _lastBarcode;
  DateTime? _lastDetectedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription =
        _controller.barcodes.listen(_handleCapture, onError: _handleError);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) unawaited(start());
    });
  }

  Future<void> start() async {
    if (!_controller.value.isRunning && !_controller.value.isStarting) {
      try {
        await _controller.start();
      } catch (error) {
        widget.onError?.call(error);
      }
    }
  }

  Future<void> stop() async {
    if (_controller.value.isRunning) {
      await _controller.stop();
    }
  }

  Future<void> toggleCamera() =>
      _controller.switchCamera(const ToggleDirection());

  @override
  void didUpdateWidget(covariant PosBackgroundBarcodeScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled == oldWidget.enabled) return;
    if (widget.enabled) {
      unawaited(start());
    } else {
      unawaited(stop());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(start());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(stop());
    }
  }

  void _handleCapture(BarcodeCapture capture) {
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (value.isEmpty) return;
    final now = DateTime.now();
    if (_lastBarcode == value &&
        _lastDetectedAt != null &&
        now.difference(_lastDetectedAt!) < widget.debounce) {
      return;
    }
    _lastBarcode = value;
    _lastDetectedAt = now;
    widget.onBarcode(value);
  }

  void _handleError(Object error, StackTrace stackTrace) {
    widget.onError?.call(error);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: 1,
        height: 1,
        child: IgnorePointer(
          child: Opacity(
            key: const ValueKey<String>('pos-background-scanner-surface'),
            opacity: 0,
            child: MobileScanner(
              controller: _controller,
              useAppLifecycleState: false,
              placeholderBuilder: (_) => const SizedBox.shrink(),
              errorBuilder: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    unawaited(_controller.dispose());
    super.dispose();
  }
}
