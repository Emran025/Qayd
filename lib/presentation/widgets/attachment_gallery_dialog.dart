import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';

/// Full-screen gallery dialog for viewing decrypted voucher/collateral images.
///
/// Features:
/// - Swipeable [PageView] with smooth transitions.
/// - Pinch-to-zoom via [InteractiveViewer].
/// - Share/Export button for individual images.
/// - Page indicator dots.
class AttachmentGalleryDialog extends StatefulWidget {
  const AttachmentGalleryDialog({
    super.key,
    required this.imageBytes,
    required this.fileNames,
    this.initialIndex = 0,
  });

  /// Decrypted image byte data for each attachment.
  final List<Uint8List> imageBytes;

  /// Human-readable file names for share functionality.
  final List<String> fileNames;

  /// Which image to show first.
  final int initialIndex;

  /// Convenience launcher for the gallery overlay.
  static Future<void> show(
    BuildContext context, {
    required List<Uint8List> imageBytes,
    required List<String> fileNames,
    int initialIndex = 0,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      useSafeArea: false,
      builder: (_) => AttachmentGalleryDialog(
        imageBytes: imageBytes,
        fileNames: fileNames,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<AttachmentGalleryDialog> createState() =>
      _AttachmentGalleryDialogState();
}

class _AttachmentGalleryDialogState extends State<AttachmentGalleryDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareCurrentImage() async {
    final bytes = widget.imageBytes[_currentIndex];
    final name = widget.fileNames[_currentIndex];
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Gallery ──────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageBytes.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.memory(
                    widget.imageBytes[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),

          // ── Top bar ─────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  '${_currentIndex + 1} / ${widget.imageBytes.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.share_rounded,
                    color: ColorTokens.goldAccent,
                  ),
                  onPressed: _shareCurrentImage,
                ),
              ],
            ),
          ),

          // ── Page indicators ─────────────────────────────────────────
          if (widget.imageBytes.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageBytes.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentIndex ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? ColorTokens.goldAccent
                          : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
