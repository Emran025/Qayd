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
  /// Returns `null` on non-Android platforms.
  Future<Directory?> externalBackupDir() async {
    Directory? extDir;
    if (Platform.isAndroid) {
      extDir = await getExternalStorageDirectory();
    }
    if (extDir == null) return null;
    final dir = Directory(p.join(extDir.path, backupDirName));
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
    final files = listBackupFiles(dir)..sort((a, b) => a.path.compareTo(b.path));
    while (files.length > keepCount) {
      try {
        await files.removeAt(0).delete();
      } catch (_) {}
    }
  }
}
