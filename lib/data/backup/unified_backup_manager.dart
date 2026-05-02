import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Handles packing and unpacking of a single ZIP archive containing
/// the database, identity file, and attachments.
class UnifiedBackupManager {
  const UnifiedBackupManager();

  static const String dbEntryName = 'qayd_finance.db';
  static const String identityEntryName = 'qayd_identity.dat';
  static const String attachmentsEntryName = 'qayd_attachments.zip';

  /// Creates a single ZIP archive containing the provided files.
  Future<File> createArchive({
    required File dbFile,
    File? identityFile,
    File? attachmentsZip,
  }) async {
    final archive = Archive();

    // 1. Add Database
    final dbBytes = await dbFile.readAsBytes();
    archive.addFile(ArchiveFile(dbEntryName, dbBytes.length, dbBytes));

    // 2. Add Identity (if exists)
    if (identityFile != null && identityFile.existsSync()) {
      final idBytes = await identityFile.readAsBytes();
      archive.addFile(
          ArchiveFile(identityEntryName, idBytes.length, idBytes));
    }

    // 3. Add Attachments ZIP (if exists)
    if (attachmentsZip != null && attachmentsZip.existsSync()) {
      final zipBytes = await attachmentsZip.readAsBytes();
      archive.addFile(
          ArchiveFile(attachmentsEntryName, zipBytes.length, zipBytes));
    }

    final zipData = ZipEncoder().encode(archive)!;
    final tmpDir = await getTemporaryDirectory();
    final outputPath = p.join(
      tmpDir.path,
      'qayd_unified_backup_${DateTime.now().millisecondsSinceEpoch}.qback',
    );
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(zipData);
    return outputFile;
  }

  /// Extracts the archive to a temporary directory and returns paths to components.
  Future<UnpackedBackup> unpack(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final tmpDir = await getTemporaryDirectory();
    final extractDir = p.join(
      tmpDir.path,
      'extract_${DateTime.now().millisecondsSinceEpoch}',
    );
    await Directory(extractDir).create(recursive: true);

    String? dbPath;
    String? identityPath;
    String? attachmentsPath;

    for (final file in archive) {
      final data = file.content as List<int>;
      final outPath = p.join(extractDir, file.name);
      final outFile = File(outPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(data);

      if (file.name == dbEntryName) {
        dbPath = outPath;
      } else if (file.name == identityEntryName) {
        identityPath = outPath;
      } else if (file.name == attachmentsEntryName) {
        attachmentsPath = outPath;
      }
    }

    return UnpackedBackup(
      databasePath: dbPath,
      identityPath: identityPath,
      attachmentsZipPath: attachmentsPath,
      tempDirectory: extractDir,
    );
  }

  /// Checks if a file is likely a unified ZIP archive.
  bool isZipArchive(String path) {
    return path.toLowerCase().endsWith('.zip') ||
        path.toLowerCase().endsWith('.qback');
  }
}

class UnpackedBackup {
  final String? databasePath;
  final String? identityPath;
  final String? attachmentsZipPath;
  final String tempDirectory;

  UnpackedBackup({
    this.databasePath,
    this.identityPath,
    this.attachmentsZipPath,
    required this.tempDirectory,
  });

  Future<void> dispose() async {
    try {
      final dir = Directory(tempDirectory);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
