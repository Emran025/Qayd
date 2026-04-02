import 'package:qayd/application/backup/dtos/backup_options.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/backup/auto_backup_service.dart';
import 'package:qayd/data/backup/backup_service.dart';

/// Orchestrates creating a backup based on user-selected options.
final class CreateBackupUseCase {
  const CreateBackupUseCase({
    required BackupService backupService,
    required AutoBackupService autoBackupService,
  })  : _backupService = backupService,
        _autoBackupService = autoBackupService;

  final BackupService _backupService;
  final AutoBackupService _autoBackupService;

  /// Creates a backup using the specified [options].
  Future<Result<String?>> call(BackupOptions options) async {
    switch (options.target) {
      case BackupTarget.share:
        final r = await _backupService.shareDatabaseBackup();
        return r.isFailure
            ? FailureResult(r.failureOrNull!)
            : const Success(null);

      case BackupTarget.saveToPath:
        if (options.destinationPath == null) {
          return const Success(null);
        }
        final r = await _backupService.saveBackupCopyToPath(
          options.destinationPath!,
        );
        return r.isFailure
            ? FailureResult(r.failureOrNull!)
            : Success(options.destinationPath);

      case BackupTarget.externalStorage:
        return _autoBackupService.saveToExternalStorage();

      case BackupTarget.autoBackup:
        final r = await _autoBackupService.runNow();
        return r.isFailure
            ? FailureResult(r.failureOrNull!)
            : const Success(null);
    }
  }
}
