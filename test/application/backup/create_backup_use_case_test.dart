import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qayd/application/backup/create_backup_use_case.dart';
import 'package:qayd/application/backup/dtos/backup_options.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/backup/auto_backup_service.dart';
import 'package:qayd/data/backup/backup_service.dart';

class MockBackupService extends Mock implements BackupService {}

class MockAutoBackupService extends Mock implements AutoBackupService {}

void main() {
  late CreateBackupUseCase useCase;
  late MockBackupService mockBackupService;
  late MockAutoBackupService mockAutoBackupService;

  setUp(() {
    mockBackupService = MockBackupService();
    mockAutoBackupService = MockAutoBackupService();
    useCase = CreateBackupUseCase(
      backupService: mockBackupService,
      autoBackupService: mockAutoBackupService,
    );
  });

  group('CreateBackupUseCase', () {
    test('Should handle BackupTarget.share correctly', () async {
      when(() => mockBackupService.shareDatabaseBackup())
          .thenAnswer((_) async => const Success(null));

      final result = await useCase(const BackupOptions(target: BackupTarget.share));

      expect(result.isSuccess, isTrue);
      verify(() => mockBackupService.shareDatabaseBackup()).called(1);
    });

    test('Should handle BackupTarget.saveToPath correctly', () async {
      when(() => mockBackupService.saveBackupCopyToPath('/backup/path'))
          .thenAnswer((_) async => const Success(null));

      final result = await useCase(const BackupOptions(
        target: BackupTarget.saveToPath,
        destinationPath: '/backup/path',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, '/backup/path');
      verify(() => mockBackupService.saveBackupCopyToPath('/backup/path')).called(1);
    });

    test('Should return success with null path if saveToPath lacks destination', () async {
      final result = await useCase(const BackupOptions(
        target: BackupTarget.saveToPath,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
      verifyNever(() => mockBackupService.saveBackupCopyToPath(any()));
    });

    test('Should handle BackupTarget.externalStorage correctly', () async {
      when(() => mockAutoBackupService.saveToExternalStorage())
          .thenAnswer((_) async => const Success('/external/path'));

      final result = await useCase(const BackupOptions(target: BackupTarget.externalStorage));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, '/external/path');
      verify(() => mockAutoBackupService.saveToExternalStorage()).called(1);
    });

    test('Should handle BackupTarget.autoBackup correctly', () async {
      when(() => mockAutoBackupService.runNow())
          .thenAnswer((_) async => const Success(null));

      final result = await useCase(const BackupOptions(target: BackupTarget.autoBackup));

      expect(result.isSuccess, isTrue);
      verify(() => mockAutoBackupService.runNow()).called(1);
    });

    test('Should propagate failures from backup services', () async {
      final failure = FileSystemFailure(messageAr: 'FS Error');
      when(() => mockBackupService.shareDatabaseBackup())
          .thenAnswer((_) async => FailureResult(failure));

      final result = await useCase(const BackupOptions(target: BackupTarget.share));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, equals(failure));
    });
  });
}
