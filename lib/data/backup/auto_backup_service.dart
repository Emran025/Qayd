import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/database/database_provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;

/// Manages automatic daily backups of [qayd_finance.db] to the device.
///
/// Behaviour (mirrors WhatsApp's local backup model):
/// - Runs a daily backup to [qayd_backups/] inside the app documents directory.
/// - **Also copies to external storage** (survives reinstall on Android using media folder).
/// - Keeps at most [_maxKeepCount] daily snapshots in each location; older ones
///   are pruned.
/// - Alongside the DB, the backup includes the identity file ([qayd_identity.dat])
///   and a copy of the DB encryption key so that restoration is possible.
/// - The user can disable automatic backups at any time.
/// - All settings are stored in encrypted platform storage.
class AutoBackupService {
  AutoBackupService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kEnabled = 'qayd_auto_backup_enabled_v1';
  static const _kLastDate = 'qayd_auto_backup_last_date_v1';

  static const String _backupDirName = 'qayd_backups';
  static const int _maxKeepCount = 7;

  // Key used to store the DB encryption key in the backup folder.
  static const String _dbKeyFileName = 'qayd_db_key.dat';
  // Identity file name (must match IdentityFileStorage._fileName).
  static const String _identityFileName = 'qayd_identity.dat';

  // ── Settings ──────────────────────────────────────────────────────────────

  /// Whether automatic daily backup is enabled (default: true).
  Future<bool> isEnabled() async {
    final raw = await _storage.read(key: _kEnabled);
    return raw != 'false';
  }

  Future<void> setEnabled(bool value) =>
      _storage.write(key: _kEnabled, value: value.toString());

  /// Returns the [DateTime] of the most recent successful auto-backup, or null.
  Future<DateTime?> lastBackupDate() async {
    final raw = await _storage.read(key: _kLastDate);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ── Core logic ────────────────────────────────────────────────────────────

  /// Performs a backup if [isEnabled] and no backup has run today.
  /// Safe to call every time the app launches.
  Future<void> performIfDue() async {
    if (!await isEnabled()) return;
    final last = await lastBackupDate();
    if (last != null) {
      final today = DateTime.now();
      if (last.year == today.year &&
          last.month == today.month &&
          last.day == today.day) {
        return; // already ran today
      }
    }
    await _runBackup();
  }

  /// Forces a backup immediately regardless of schedule.
  Future<Result<void>> runNow() async {
    try {
      await _runBackup();
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        FileSystemFailure(messageAr: 'تعذر إنشاء النسخة الاحتياطية التلقائية.'),
      );
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _runBackup() async {
    final srcPath = await DatabaseProvider.databaseFilePath();
    if (!File(srcPath).existsSync()) return;

    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    final dbFileName = 'qayd_backup_$stamp.db';

    // 1. Backup to internal (app documents) directory.
    final internalDir = await _localBackupDir();
    final internalDest = p.join(internalDir.path, dbFileName);
    await File(srcPath).copy(internalDest);
    await _copyKeyAndIdentityTo(internalDir);
    await _pruneOld(internalDir);

    // 2. Also backup to external storage (survives reinstall on Android).
    try {
      final externalDir = await _externalBackupDir();
      if (externalDir != null && externalDir.path != internalDir.path) {
        final externalDest = p.join(externalDir.path, dbFileName);
        await File(srcPath).copy(externalDest);
        await _copyKeyAndIdentityTo(externalDir);
        await _pruneOld(externalDir);
      }
    } catch (_) {
      // External storage unavailable — non-fatal.
    }

    await _storage.write(
      key: _kLastDate,
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Copies the DB encryption key and identity file alongside the backup.
  Future<void> _copyKeyAndIdentityTo(Directory backupDir) async {
    // Copy DB encryption key (from secure storage) to a file in the backup dir.
    try {
      final dbKey = await _storage.read(key: 'qayd_db_derived_key_v2');
      if (dbKey != null && dbKey.isNotEmpty) {
        final keyFile = File(p.join(backupDir.path, _dbKeyFileName));
        await keyFile.writeAsString(dbKey);
      }
    } catch (_) {}

    // Copy identity file if it exists.
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final identityFile = File(p.join(docsDir.path, _identityFileName));
      if (identityFile.existsSync()) {
        final dest = File(p.join(backupDir.path, _identityFileName));
        await identityFile.copy(dest.path);
      }
    } catch (_) {}
  }

  Future<Directory> _localBackupDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _backupDirName));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Returns the external backup directory. On Android this persists across
  /// reinstalls without needing WRITE_EXTERNAL_STORAGE on Android 10+ (using media folder).
  /// Returns null if not available.
  Future<Directory?> _externalBackupDir() async {
    Directory? extDir;
    if (Platform.isAndroid) {
      // Use the media directory as it's more likely to survive app uninstallation
      // than the standard data folder on many Android builds.
      final paths =
          await getExternalStorageDirectories(type: StorageDirectory.documents);
      if (paths != null && paths.isNotEmpty) {
        // e.g. /storage/emulated/0/Android/data/com.example.app/files/Documents
        // We want to transform this into /storage/emulated/0/Android/media/com.example.app/
        final parts = p.split(paths.first.path);
        final androidIdx = parts.indexOf('Android');
        if (androidIdx != -1 && androidIdx + 1 < parts.length) {
          final pkgName = parts[androidIdx + 2]; // com.example.app
          final mediaRoot = p.joinAll(parts.sublist(0, androidIdx + 1).toList()
            ..addAll(['media', pkgName]));
          extDir = Directory(mediaRoot);
        }
      }
    }

    if (extDir == null) return null;
    final dir = Directory(p.join(extDir.path, _backupDirName));
    try {
      if (!dir.existsSync()) await dir.create(recursive: true);
      return dir;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pruneOld(Directory dir) async {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    while (files.length > _maxKeepCount) {
      try {
        await files.removeAt(0).delete();
      } catch (_) {}
    }
  }

  // ── Recovery / Discovery ──────────────────────────────────────────────────

  /// Finds the latest available local backup across all known locations.
  /// Used during app reinstall to offer restoration.
  Future<File?> latestLocalBackup() async {
    try {
      final internalDir = await _localBackupDir();
      final externalDir = await _externalBackupDir();

      final allFiles = <File>[];
      if (internalDir.existsSync()) {
        allFiles.addAll(internalDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.db')));
      }
      if (externalDir != null && externalDir.existsSync()) {
        allFiles.addAll(externalDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.db')));
      }

      if (allFiles.isEmpty) return null;

      allFiles.sort((a, b) =>
          b.path.compareTo(a.path)); // Newest first by timestamp in name
      return allFiles.first;
    } catch (_) {
      return null;
    }
  }

  /// Attempts to find the DB encryption key file alongside the given backup file.
  Future<String?> findKeyForBackup(File backupFile) async {
    final dir = backupFile.parent;
    final keyFile = File(p.join(dir.path, _dbKeyFileName));
    if (keyFile.existsSync()) {
      return keyFile.readAsString();
    }
    return null;
  }

  /// Attempts to find the identity file alongside the given backup file.
  Future<File?> findIdentityForBackup(File backupFile) async {
    final dir = backupFile.parent;
    final idFile = File(p.join(dir.path, _identityFileName));
    if (idFile.existsSync()) return idFile;
    return null;
  }

  // ── Save to external storage ──────────────────────────────────────────────

  /// Copies the latest backup (or creates one) to the external app directory.
  ///
  /// On Android this is the persistent media directory.
  /// On iOS it falls back to the documents directory.
  Future<Result<String>> saveToExternalStorage() async {
    try {
      final srcPath = await DatabaseProvider.databaseFilePath();
      final backupFolder =
          await _externalBackupDir() ?? await _localBackupDir();

      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final destPath = p.join(backupFolder.path, 'qayd_backup_$stamp.db');
      await File(srcPath).copy(destPath);

      // Also copy key and identity alongside.
      await _copyKeyAndIdentityTo(backupFolder);

      return Success(destPath);
    } catch (_) {
      return const FailureResult(
        FileSystemFailure(
          messageAr: 'تعذر حفظ النسخة الاحتياطية في وحدة التخزين الخارجية.',
        ),
      );
    }
  }

  /// Shares the latest DB backup via the system share sheet.
  Future<Result<void>> shareBackup() async {
    try {
      final srcPath = await DatabaseProvider.databaseFilePath();
      if (!File(srcPath).existsSync()) {
        return const FailureResult(
            FileSystemFailure(messageAr: 'قاعدة البيانات غير موجودة.'));
      }
      final tmpDir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final tmp = p.join(tmpDir.path, 'qayd_backup_$stamp.db');
      await File(srcPath).copy(tmp);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tmp, mimeType: 'application/octet-stream')],
        ),
      );
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        FileSystemFailure(messageAr: 'تعذر مشاركة النسخة الاحتياطية.'),
      );
    }
  }

  /// Lists all locally stored backup files sorted newest-first.
  Future<List<File>> listLocalBackups() async {
    try {
      final dir = await _localBackupDir();
      final extDir = await _externalBackupDir();

      final files = <File>[];
      if (dir.existsSync()) {
        files.addAll(dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.db')));
      }
      if (extDir != null && extDir.existsSync()) {
        files.addAll(extDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.db')));
      }

      files.sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (_) {
      return [];
    }
  }

  /// Deletes all local backup files from internal and external storage.
  Future<void> deleteAllBackups() async {
    try {
      final internalDir = await _localBackupDir();
      if (internalDir.existsSync()) {
        await internalDir.delete(recursive: true);
      }
      final externalDir = await _externalBackupDir();
      if (externalDir != null && externalDir.existsSync()) {
        await externalDir.delete(recursive: true);
      }
    } catch (_) {}
    await _storage.delete(key: _kLastDate);
  }
}
