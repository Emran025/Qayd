import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages backup file locations and cleanup on the local file system.
///
/// Centralises path resolution so both [AutoBackupService] and
/// [BackupService] resolve to the same directories.
final class BackupFileManager {
  const BackupFileManager();

  static const String backupDirName = 'qayd_backups';
  static const String identityFileName = 'qayd_identity.dat';
  static const String dbKeyFileName = 'qayd_db_key.dat';

  /// Internal backup directory (app documents — may be deleted on uninstall).
  Future<Directory> internalBackupDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, backupDirName));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// External backup directory (survives uninstall on Android).
  ///
  /// On Android, this uses the /Android/media/pkg_name/ folder which is
  /// often preserved during app updates or quick re-installs.
  /// Returns `null` on non-Android platforms.
  Future<Directory?> externalBackupDir() async {
    Directory? extDir;
    if (Platform.isAndroid) {
      // Logic from AutoBackupService to find the media folder
      final paths =
          await getExternalStorageDirectories(type: StorageDirectory.documents);
      if (paths != null && paths.isNotEmpty) {
        final parts = p.split(paths.first.path);
        final androidIdx = parts.indexOf('Android');
        if (androidIdx != -1 && androidIdx + 1 < parts.length) {
          final pkgName = parts[androidIdx + 2];
          final mediaRoot = p.joinAll(parts.sublist(0, androidIdx + 1).toList()
            ..addAll(['media', pkgName]));
          extDir = Directory(mediaRoot);
        }
      }
    }
    if (extDir == null) return null;
    final dir = Directory(p.join(extDir.path, backupDirName));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// External images directory for voucher attachments (survives uninstall on Android).
  Future<Directory?> externalImagesDir() async {
    Directory? extDir;
    if (Platform.isAndroid) {
      final paths =
          await getExternalStorageDirectories(type: StorageDirectory.documents);
      if (paths != null && paths.isNotEmpty) {
        final parts = p.split(paths.first.path);
        final androidIdx = parts.indexOf('Android');
        if (androidIdx != -1 && androidIdx + 1 < parts.length) {
          final pkgName = parts[androidIdx + 2];
          final mediaRoot = p.joinAll(parts.sublist(0, androidIdx + 1).toList()
            ..addAll(['media', pkgName]));
          extDir = Directory(mediaRoot);
        }
      }
    }

    // Default to app documents/images if external is unavailable
    final base = extDir ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'qayd_images'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Lists all `.db` backup files in [dir] sorted newest-first.
  List<File> listBackupFiles(Directory dir) {
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
  }

  /// Deletes old backup files keeping at most [keepCount].
  Future<void> pruneOldBackups(Directory dir, {int keepCount = 7}) async {
    final files = listBackupFiles(dir)
      ..sort((a, b) => a.path.compareTo(b.path));
    while (files.length > keepCount) {
      try {
        await files.removeAt(0).delete();
      } catch (_) {}
    }
  }
}
