import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/backup/attachments_zip_builder.dart';
import 'package:qayd/data/backup/qayd_database_validator.dart';
import 'package:qayd/data/database/database_encryption_key_provider.dart';
import 'package:qayd/data/database/database_provider.dart';
import 'package:qayd/data/backup/unified_backup_manager.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;

/// Copies the live encrypted DB and shares it, or restores from a validated backup.
///
/// When sharing or saving, also includes the identity file alongside the DB
/// so the user has a complete backup including signing keys.
class BackupService {
  BackupService({
    required DatabaseEncryptionKeyProvider keyProvider,
    AttachmentsZipBuilder? zipBuilder,
    UnifiedBackupManager? unifiedManager,
  })  : _keyProvider = keyProvider,
        _zipBuilder = zipBuilder ?? const AttachmentsZipBuilder(),
        _unifiedManager = unifiedManager ?? const UnifiedBackupManager();

  final DatabaseEncryptionKeyProvider _keyProvider;
  final AttachmentsZipBuilder _zipBuilder;
  final UnifiedBackupManager _unifiedManager;

  // Must match IdentityFileStorage._fileName.
  static const String _identityFileName = 'qayd_identity.dat';

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

  /// Returns the identity file path (if it exists).
  Future<File?> _findIdentityFile() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final f = File(p.join(docsDir.path, _identityFileName));
      if (f.existsSync()) return f;
    } catch (_) {}
    return null;
  }

  Future<Result<void>> shareDatabaseBackup() async {
    try {
      final dbFile = await copyDatabaseToTempFile();
      final idFile = await _findIdentityFile();
      File? zipFile;
      try {
        zipFile = await _zipBuilder.buildZipToTemp();
      } catch (_) {}

      final archive = await _unifiedManager.createArchive(
        dbFile: dbFile,
        identityFile: idFile,
        attachmentsZip: zipFile,
      );

      await SharePlus.instance.share(
        ShareParams(files: [XFile(archive.path, mimeType: 'application/zip')]),
      );
      return const Success(null);
    } catch (_) {
      return FailureResult(
        FileSystemFailure(messageAr: AppStrings.unableToCreateOr),
      );
    }
  }

  /// Validates without replacing the live DB (e.g. before showing restore confirmation).
  Future<Result<void>> validateBackupFile(String backupPath,
      {String? customKey}) async {
    final key = customKey ?? await _key();

    if (_unifiedManager.isZipArchive(backupPath)) {
      final unpacked = await _unifiedManager.unpack(backupPath);
      try {
        if (unpacked.databasePath == null) {
          return FailureResult(
              ValidationFailure(messageAr: AppStrings.theFileDoesNot1));
        }
        return await QaydDatabaseValidator.validateFile(
          path: unpacked.databasePath!,
          encryptionKey: key,
        );
      } finally {
        await unpacked.dispose();
      }
    }

    return QaydDatabaseValidator.validateFile(
      path: backupPath,
      encryptionKey: key,
    );
  }

  /// Creates the unified archive and returns the temporary [File].
  Future<Result<File>> createUnifiedBackupFile() async {
    try {
      final dbFile = await copyDatabaseToTempFile();
      final idFile = await _findIdentityFile();
      File? zipFile;
      try {
        zipFile = await _zipBuilder.buildZipToTemp();
      } catch (_) {}

      final archive = await _unifiedManager.createArchive(
        dbFile: dbFile,
        identityFile: idFile,
        attachmentsZip: zipFile,
      );
      return Success(archive);
    } catch (e) {
      return FailureResult(
          FileSystemFailure(messageAr: 'تعذر إنشاء ملف النسخة الاحتياطية: $e'));
    }
  }

  /// Writes a fresh file copy via temp (avoids locking issues on some platforms).
  Future<Result<void>> saveBackupCopyToPath(String destinationPath) async {
    try {
      final dbFile = await copyDatabaseToTempFile();
      final idFile = await _findIdentityFile();
      File? zipFile;
      try {
        zipFile = await _zipBuilder.buildZipToTemp();
      } catch (_) {}

      final archive = await _unifiedManager.createArchive(
        dbFile: dbFile,
        identityFile: idFile,
        attachmentsZip: zipFile,
      );

      await archive.copy(destinationPath);
      return const Success(null);
    } catch (_) {
      return FailureResult(
        FileSystemFailure(messageAr: AppStrings.theConsolidatedBackupCould),
      );
    }
  }

  /// Validates then replaces the app DB file. The live DB connection must be closed first.
  Future<Result<void>> replaceDatabaseFromBackupFile(String backupPath,
      {String? customKey}) async {
    final key = customKey ?? await _key();

    String finalDbPath = backupPath;
    String? finalIdPath;
    String? finalAttachmentsZipPath;
    UnpackedBackup? unpacked;

    if (_unifiedManager.isZipArchive(backupPath)) {
      unpacked = await _unifiedManager.unpack(backupPath);
      if (unpacked.databasePath == null) {
        await unpacked.dispose();
        return FailureResult(
            ValidationFailure(messageAr: AppStrings.theFileDoesNot));
      }
      finalDbPath = unpacked.databasePath!;
      finalIdPath = unpacked.identityPath;
      finalAttachmentsZipPath = unpacked.attachmentsZipPath;
    } else {
      // Legacy behavior: check side-by-side
      final backupDir = File(backupPath).parent.path;
      final idSource = File(p.join(backupDir, _identityFileName));
      if (idSource.existsSync()) {
        finalIdPath = idSource.path;
      }
      final zipSource =
          File(p.join(backupDir, AttachmentsZipBuilder.zipFileName));
      if (zipSource.existsSync()) {
        finalAttachmentsZipPath = zipSource.path;
      }
    }

    final v = await QaydDatabaseValidator.validateFile(
      path: finalDbPath,
      encryptionKey: key,
    );
    if (v.isFailure) {
      if (unpacked != null) await unpacked.dispose();
      return FailureResult(v.failureOrNull!);
    }

    try {
      final target = await DatabaseProvider.databaseFilePath();
      final tmp = '$target.tmp_restore';
      await File(finalDbPath).copy(tmp);
      final targetFile = File(target);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await File(tmp).copy(target);
      try {
        await File(tmp).delete();
      } catch (_) {}

      // Restore identity file if present.
      if (finalIdPath != null && File(finalIdPath).existsSync()) {
        final docsDir = await getApplicationDocumentsDirectory();
        final idDest = File(p.join(docsDir.path, _identityFileName));
        await File(finalIdPath).copy(idDest.path);
      }

      // Restore attachments ZIP if present.
      if (finalAttachmentsZipPath != null &&
          File(finalAttachmentsZipPath).existsSync()) {
        try {
          await _zipBuilder.restoreFromZip(finalAttachmentsZipPath);
        } catch (_) {}
      }

      return const Success(null);
    } catch (_) {
      return FailureResult(
        FileSystemFailure(messageAr: AppStrings.theDatabaseFileCould),
      );
    } finally {
      if (unpacked != null) await unpacked.dispose();
    }
  }
}
