import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/backup/qayd_database_validator.dart';
import 'package:qayd/data/database/database_encryption_key_provider.dart';
import 'package:qayd/data/database/database_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Copies the live encrypted DB and shares it, or restores from a validated backup.
final class BackupService {
  BackupService({
    required DatabaseEncryptionKeyProvider keyProvider,
  }) : _keyProvider = keyProvider;

  final DatabaseEncryptionKeyProvider _keyProvider;

  Future<String> _key() => _keyProvider.obtainKey();

  /// Copies [qayd_finance.db] to a temp file with a timestamped name (bytes only).
  Future<File> copyDatabaseToTempFile() async {
    final srcPath = await DatabaseProvider.databaseFilePath();
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final out = File(p.join(dir.path, 'qayd_backup_$stamp.db'));
    await File(srcPath).copy(out.path);
    return out;
  }

  Future<Result<void>> shareDatabaseBackup() async {
    try {
      final f = await copyDatabaseToTempFile();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(f.path, mimeType: 'application/octet-stream')],
        ),
      );
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        FileSystemFailure(messageAr: 'تعذر إنشاء أو مشاركة النسخة الاحتياطية.'),
      );
    }
  }

  /// Validates without replacing the live DB (e.g. before showing restore confirmation).
  Future<Result<void>> validateBackupFile(String backupPath) async {
    final key = await _key();
    return QaydDatabaseValidator.validateFile(
      path: backupPath,
      encryptionKey: key,
    );
  }

  /// Writes a fresh file copy via temp (avoids locking issues on some platforms).
  Future<Result<void>> saveBackupCopyToPath(String destinationPath) async {
    try {
      final f = await copyDatabaseToTempFile();
      await f.copy(destinationPath);
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        FileSystemFailure(messageAr: 'تعذر حفظ النسخة الاحتياطية في المسار المحدد.'),
      );
    }
  }

  /// Validates then replaces the app DB file. The live DB connection must be closed first.
  Future<Result<void>> replaceDatabaseFromBackupFile(String backupPath) async {
    final key = await _key();
    final v = await QaydDatabaseValidator.validateFile(
      path: backupPath,
      encryptionKey: key,
    );
    if (v.isFailure) {
      return FailureResult(v.failureOrNull!);
    }
    try {
      final target = await DatabaseProvider.databaseFilePath();
      final tmp = '$target.tmp_restore';
      await File(backupPath).copy(tmp);
      final targetFile = File(target);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await File(tmp).copy(target);
      try {
        await File(tmp).delete();
      } catch (_) {}
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        FileSystemFailure(messageAr: 'تعذر استبدال ملف قاعدة البيانات.'),
      );
    }
  }
}
