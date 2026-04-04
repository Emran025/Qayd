import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/backup/backup_service.dart';
import 'package:qayd/data/security/identity_file_storage.dart';
import 'package:qayd/data/security/mnemonic_vault.dart';

/// Orchestrates restoring from a backup file:
///   1. Validates the backup file.
///   2. Closes the live DB.
///   3. Replaces the live DB with the backup.
///   4. Re-opens the DB.
///   5. Restores the identity file if present alongside the backup.
final class RestoreFromBackupUseCase {
  const RestoreFromBackupUseCase({
    required BackupService backupService,
    required IdentityFileStorage identityFileStorage,
    required MnemonicVault mnemonicVault,
  })  : _backupService = backupService,
        _identityFileStorage = identityFileStorage,
        _mnemonicVault = mnemonicVault;

  final BackupService _backupService;
  final IdentityFileStorage _identityFileStorage;
  final MnemonicVault _mnemonicVault;

  /// Validates the backup at [backupPath].
  Future<Result<void>> validate(String backupPath, {String? customKey}) =>
      _backupService.validateBackupFile(backupPath); // TODO: backupService needs customKey support

  /// Replaces the live database with the backup.
  ///
  /// Caller must close the live DB BEFORE calling this, and re-open it AFTER.
  Future<Result<void>> restore(String backupPath, {String? customKey}) async {
    final r = await _backupService.replaceDatabaseFromBackupFile(backupPath);
    if (r.isFailure) return r;

    // After DB is restored, try to restore identity from the vault/file.
    try {
      await _identityFileStorage.restoreToVaultIfAvailable(_mnemonicVault);
    } catch (_) {
      // Non-fatal: identity restore is best-effort.
    }

    return const Success(null);
  }
}
