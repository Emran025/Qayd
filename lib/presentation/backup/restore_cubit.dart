import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/backup/auto_backup_service.dart';
import 'package:qayd/data/backup/google_drive_backup_service.dart';
import 'package:qayd/data/database/hardware_backed_encryption_key_provider.dart';
import 'package:qayd/application/backup/restore_from_backup_use_case.dart';
import 'package:qayd/data/security/mnemonic_vault.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';

abstract class RestoreState {}

class RestoreInitial extends RestoreState {}

class RestoreChecking extends RestoreState {
  RestoreChecking({this.localFile, this.driveInfo});
  final File? localFile;
  final DriveBackupInfo? driveInfo;
}

class RestoreFound extends RestoreState {
  RestoreFound({required this.localFile, this.driveInfo});
  final File localFile;
  final DriveBackupInfo? driveInfo;
}

class RestoreNoBackupFound extends RestoreState {}

class RestoreNeedsPrimaryKey extends RestoreState {
  RestoreNeedsPrimaryKey({required this.backupPath, this.isDrive = false});
  final String backupPath;
  final bool isDrive;
}

class RestoreInProgess extends RestoreState {}

class RestoreSuccess extends RestoreState {}

class RestoreFailure extends RestoreState {
  RestoreFailure(this.errorAr);
  final String errorAr;
}

class RestoreCubit extends Cubit<RestoreState> {
  RestoreCubit({
    required AutoBackupService autoBackupService,
    required GoogleDriveBackupService driveService,
    required RestoreFromBackupUseCase restoreUseCase,
    required HardwareBackedEncryptionKeyProvider keyProvider,
    required MnemonicVault mnemonicVault,
  })  : _autoBackupService = autoBackupService,
        _driveService = driveService,
        _restoreUseCase = restoreUseCase,
        _keyProvider = keyProvider,
        _mnemonicVault = mnemonicVault,
        super(RestoreInitial());

  final AutoBackupService _autoBackupService;
  final GoogleDriveBackupService _driveService;
  final RestoreFromBackupUseCase _restoreUseCase;
  final HardwareBackedEncryptionKeyProvider _keyProvider;
  final MnemonicVault _mnemonicVault;

  Future<void> checkBackups() async {
    emit(RestoreChecking());
    
    // 1. Check local
    final local = await _autoBackupService.latestLocalBackup();
    
    // 2. Check Drive (if signed in)
    DriveBackupInfo? driveInfo;
    if (_driveService.isSignedIn) {
      final driveResult = await _driveService.checkForBackup();
      if (driveResult.isSuccess) {
        driveInfo = driveResult.valueOrNull;
      }
    }

    if (local != null || driveInfo != null) {
      emit(RestoreFound(localFile: local ?? File(''), driveInfo: driveInfo));
    } else {
      emit(RestoreNoBackupFound());
    }
  }

  Future<void> performRestore({File? localFile, bool fromDrive = false}) async {
    emit(RestoreInProgess());

    String? path;
    if (fromDrive) {
      final download = await _driveService.downloadBackup();
      if (download.isFailure) {
        emit(RestoreFailure('فشل تحميل النسخة من Drive.'));
        return;
      }
      path = download.valueOrNull;
    } else if (localFile != null) {
      path = localFile.path;
    }

    if (path == null) {
      emit(RestoreFailure('لم يتم العثور على ملف لاستعادته.'));
      return;
    }

    // Try to find key file alongside backup
    final keyString = await _autoBackupService.findKeyForBackup(File(path));
    
    // Validate first
    final validation = await _restoreUseCase.validate(path, customKey: keyString);
    if (validation.isFailure) {
      // If validation failed because of key, ask for Primary Key
      emit(RestoreNeedsPrimaryKey(backupPath: path, isDrive: fromDrive));
      return;
    }

    // Perform restore
    final result = await _restoreUseCase.restore(path, customKey: keyString);
    if (result.isSuccess) {
      if (keyString != null) {
        await _keyProvider.updateCachedKey(keyString);
      }
      emit(RestoreSuccess());
    } else {
      emit(RestoreFailure('فشل عملية الاستعادة.'));
    }
  }

  Future<void> restoreWithPrimaryKey(String path, String mnemonicPhrase) async {
    emit(RestoreInProgess());

    try {
      final customKey = await _keyProvider.deriveKeyFromMnemonic(mnemonicPhrase);
      
      final validation = await _restoreUseCase.validate(path, customKey: customKey);
      if (validation.isFailure) {
        emit(RestoreFailure('المفتاح الأساسي غير صحيح أو لا ينتمي لهذه النسخة.'));
        return;
      }

      final result = await _restoreUseCase.restore(path, customKey: customKey);
      if (result.isSuccess) {
        await _keyProvider.updateCachedKey(customKey);
        // Save the mnemonic so identity is also restored
        await _mnemonicVault.writeMnemonic(MnemonicPhrase.fromPhrase(mnemonicPhrase));
        emit(RestoreSuccess());
      } else {
        emit(RestoreFailure('فشل استبدال قاعدة البيانات باستخدام المفتاح الأساسي.'));
      }
    } catch (e) {
      emit(RestoreFailure('خطأ في معالجة المفتاح الأساسي: $e'));
    }
  }
}
