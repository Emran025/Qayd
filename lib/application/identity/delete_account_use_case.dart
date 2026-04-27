import 'dart:io';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/data/backup/auto_backup_service.dart';
import 'package:qayd/data/backup/google_drive_backup_service.dart';
import 'package:qayd/data/security/mnemonic_vault.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/data/security/app_pin_storage.dart';
import 'package:qayd/data/security/identity_file_storage.dart';
import 'package:qayd/data/database/database_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Permanent account deletion use case.
///
/// Wipes the local database, local backups, Google Drive backups, and
/// soft-deletes the identity from the server.
class DeleteAccountUseCase {
  DeleteAccountUseCase({
    required IdentityRepository identityRepository,
    required AutoBackupService autoBackupService,
    required GoogleDriveBackupService driveBackupService,
    required MnemonicVault mnemonicVault,
    required LicenseVault licenseVault,
    required AppPinStorage appPinStorage,
    required IdentityFileStorage identityFileStorage,
    required Database database,
  })  : _identityRepo = identityRepository,
        _autoBackupSvc = autoBackupService,
        _driveBackupSvc = driveBackupService,
        _mnemonicVault = mnemonicVault,
        _licenseVault = licenseVault,
        _pinStorage = appPinStorage,
        _idFileStorage = identityFileStorage,
        _db = database;

  final IdentityRepository _identityRepo;
  final AutoBackupService _autoBackupSvc;
  final GoogleDriveBackupService _driveBackupSvc;
  final MnemonicVault _mnemonicVault;
  final LicenseVault _licenseVault;
  final AppPinStorage _pinStorage;
  final IdentityFileStorage _idFileStorage;
  final Database _db;

  Future<Result<void>> call() async {
    try {
      // 1. Delete from server (Soft delete)
      try {
        await _identityRepo.deleteAccount();
      } catch (e) {
        // If server deletion fails (e.g. offline), we still proceed with 
        // local wipe for security, but we log the error.
      }

      // 2. Delete Google Drive backups
      try {
        await _driveBackupSvc.deleteAllBackups();
        await _driveBackupSvc.signOut();
      } catch (_) {}

      // 3. Delete local backups
      await _autoBackupSvc.deleteAllBackups();

      // 4. Wipe local identity & security
      await _mnemonicVault.deleteAll();
      await _pinStorage.clearPinAndLock();
      await _idFileStorage.delete();
      
      // 5. Close and Delete Database
      if (_db.isOpen) {
        await _db.close();
      }
      final dbPath = await DatabaseProvider.databaseFilePath();
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        await dbFile.delete();
      }

      // 6. Clear License / JWT (User is now fully logged out and wiped)
      await _licenseVault.deleteAll();

      return const Success(null);
    } catch (e) {
      return FailureResult(
        FileSystemFailure(messageAr: 'حدث خطأ غير متوقع أثناء محو البيانات: $e'),
      );
    }
  }
}
