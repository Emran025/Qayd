import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

/// A unified, premium QR/Barcode scanner component for the Qayd ecosystem.
/// Features an animated focus frame, laser line, and customizable overlay.
class QaydQrScanner extends StatefulWidget {
  const QaydQrScanner({
    super.key,
    required this.onDetect,
    this.title,
    this.hint,
    this.onClose,
  });

  /// Called when a code is successfully detected.
  final ValueChanged<String> onDetect;

  /// Optional title shown at the top.
  final String? title;

  /// Optional hint shown at the bottom.
  final String? hint;

  /// Optional callback for the close button.
  final VoidCallback? onClose;

  @override
  State<QaydQrScanner> createState() => _QaydQrScannerState();
}

class _QaydQrScannerState extends State<QaydQrScanner>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasPermission = false;
  bool _permissionRequested = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _hasPermission = status.isGranted;
      _permissionRequested = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    if (!_permissionRequested) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_photography_rounded, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  AppStrings.permissionCameraMissingBodyQr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _requestPermission,
                child: Text(AppStrings.actionApprove),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final code = capture.barcodes.first.rawValue;
              if (code != null && code.isNotEmpty) {
                widget.onDetect(code);
              }
            },
          ),

          // 2. Black Overlay with Cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                Center(
                  child: Container(
                    width: scanAreaSize,
                    height: scanAreaSize,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Animated Focus Frame & Laser
          Center(
            child: SizedBox(
              width: scanAreaSize,
              height: scanAreaSize,
              child: Stack(
                children: [
                  // Animated Laser Line
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * scanAreaSize,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0),
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Decorative Corners
                  CustomPaint(
                    painter: _ScannerFramePainter(
                      color: theme.colorScheme.primary,
                    ),
                    size: Size(scanAreaSize, scanAreaSize),
                  ),
                ],
              ),
            ),
          ),

          // 4. UI Elements (Back, Flash, Title)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: widget.onClose ?? () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                ),
                if (widget.title != null)
                  Expanded(
                    child: Text(
                      widget.title!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, state, child) {
                    final torchState = state.torchState;
                    return IconButton(
                      onPressed: () => _controller.toggleTorch(),
                      icon: Icon(
                        torchState == TorchState.on
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black26,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          if (widget.hint != null)
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Text(
                widget.hint!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  final Color color;
  _ScannerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const cornerLength = 30.0;
    const radius = 24.0;

    // Top Left
    path.moveTo(0, cornerLength);
    path.lineTo(0, radius);
    path.arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius));
    path.lineTo(cornerLength, 0);

    // Top Right
    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(Offset(size.width, radius),
        radius: const Radius.circular(radius));
    path.lineTo(size.width, cornerLength);

    // Bottom Right
    path.moveTo(size.width, size.height - cornerLength);
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(Offset(size.width - radius, size.height),
        radius: const Radius.circular(radius));
    path.lineTo(size.width - cornerLength, size.height);

    // Bottom Left
    path.moveTo(cornerLength, size.height);
    path.lineTo(radius, size.height);
    path.arcToPoint(Offset(0, size.height - radius),
        radius: const Radius.circular(radius));
    path.lineTo(0, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
