import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;
import 'package:url_launcher/url_launcher.dart';

/// Writes arbitrary bytes to a temp file and opens the platform share sheet.
Future<void> shareExportBytes(
  Uint8List bytes,
  String fileName, {
  required String mimeType,
}) async {
  final dir = await getTemporaryDirectory();
  final safeName = fileName.trim().isEmpty ? 'export.bin' : fileName;
  final path = p.join(dir.path, safeName);
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    final uri = Uri.file(path);
    try {
      await launchUrl(uri);
      return;
    } catch (_) {
      // Fallback if launchUrl fails
    }
  }

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: mimeType)],
    ),
  );
}
