import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes PDF bytes to a temp file and opens the platform share sheet.
Future<void> sharePdfBytes(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final safeName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
  final path = p.join(dir.path, safeName);
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'application/pdf')],
    ),
  );
}
