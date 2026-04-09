import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  await Share.shareXFiles(
    [XFile(path, mimeType: mimeType)],
  );
}
