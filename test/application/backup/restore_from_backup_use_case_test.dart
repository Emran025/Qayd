import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/backup/restore_from_backup_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/backup/backup_service.dart';
import 'package:qayd/data/security/identity_file_storage.dart';
import 'package:qayd/data/security/mnemonic_vault.dart';

class MockBackupService extends Mock implements BackupService {}

class MockIdentityFileStorage extends Mock implements IdentityFileStorage {}

class MockMnemonicVault extends Mock implements MnemonicVault {}

class FakeMnemonicVault extends Fake implements MnemonicVault {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMnemonicVault());
  });

  late RestoreFromBackupUseCase useCase;
  late MockBackupService mockBackupService;
  late MockIdentityFileStorage mockIdentityFileStorage;
  late MockMnemonicVault mockMnemonicVault;

  setUp(() {
    mockBackupService = MockBackupService();
    mockIdentityFileStorage = MockIdentityFileStorage();
    mockMnemonicVault = MockMnemonicVault();
    useCase = RestoreFromBackupUseCase(
      backupService: mockBackupService,
      identityFileStorage: mockIdentityFileStorage,
      mnemonicVault: mockMnemonicVault,
    );
  });

  group('RestoreFromBackupUseCase - validate', () {
    test('Should return success if validation passes', () async {
      when(() => mockBackupService.validateBackupFile('/path/backup.zip'))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase.validate('/path/backup.zip');

      expect(result.isSuccess, isTrue);
      verify(() => mockBackupService.validateBackupFile('/path/backup.zip')).called(1);
    });

    test('Should return failure if validation fails', () async {
      final failure = FileSystemFailure(messageAr: 'Invalid Backup');
      when(() => mockBackupService.validateBackupFile('/path/backup.zip'))
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase.validate('/path/backup.zip');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });
  });

  group('RestoreFromBackupUseCase - restore', () {
    test('Should restore successfully and attempt identity restore', () async {
      when(() => mockBackupService.replaceDatabaseFromBackupFile('/path/backup.zip'))
          .thenAnswer((_) async => const Success(null));
      when(() => mockIdentityFileStorage.restoreToVaultIfAvailable(mockMnemonicVault))
          .thenAnswer((_) async => true);

      final result = await useCase.restore('/path/backup.zip');

      expect(result.isSuccess, isTrue);
      verify(() => mockBackupService.replaceDatabaseFromBackupFile('/path/backup.zip')).called(1);
      verify(() => mockIdentityFileStorage.restoreToVaultIfAvailable(mockMnemonicVault)).called(1);
    });

    test('Should not fail restore if identity restore throws', () async {
      when(() => mockBackupService.replaceDatabaseFromBackupFile('/path/backup.zip'))
          .thenAnswer((_) async => const Success(null));
      when(() => mockIdentityFileStorage.restoreToVaultIfAvailable(mockMnemonicVault))
          .thenThrow(Exception('Vault Error'));

      final result = await useCase.restore('/path/backup.zip');

      expect(result.isSuccess, isTrue);
      verify(() => mockBackupService.replaceDatabaseFromBackupFile('/path/backup.zip')).called(1);
      verify(() => mockIdentityFileStorage.restoreToVaultIfAvailable(mockMnemonicVault)).called(1);
    });

    test('Should propagate failure from backup replace operation', () async {
      final failure = FileSystemFailure(messageAr: 'Replace Failed');
      when(() => mockBackupService.replaceDatabaseFromBackupFile('/path/backup.zip'))
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase.restore('/path/backup.zip');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
      verifyNever(() => mockIdentityFileStorage.restoreToVaultIfAvailable(any()));
    });
  });
}
