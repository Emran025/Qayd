import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/database/database_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Ensures a file is an encrypted Qayd database (SQLCipher + expected tables).
abstract final class QaydDatabaseValidator {
  static Future<Result<void>> validateFile({
    required String path,
    required String encryptionKey,
  }) async {
    Database? db;
    try {
      db = await openDatabase(
        path,
        password: encryptionKey,
        readOnly: true,
        singleInstance: false,
      );
      final uvRows = await db.rawQuery('PRAGMA user_version');
      final rawUv = uvRows.first.values.first;
      final userVersion = rawUv is int ? rawUv : (rawUv as num).toInt();
      if (userVersion < 1 ||
          userVersion > DatabaseProvider.schemaVersion + 50) {
        await db.close();
        return const FailureResult(
          ValidationFailure(
            messageAr: 'نسخة قاعدة البيانات غير مدعومة.',
            code: 'backup_schema',
          ),
        );
      }
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final names = tables.map((e) => e['name'] as String).toSet();
      if (!names.contains('accounts') || !names.contains('vouchers')) {
        await db.close();
        return const FailureResult(
          ValidationFailure(
            messageAr: 'الملف لا يحتوي على جداول قيد متوقعة.',
            code: 'backup_tables',
          ),
        );
      }
      await db.close();
      return const Success(null);
    } catch (_) {
      try {
        await db?.close();
      } catch (_) {}
      return const FailureResult(
        ValidationFailure(
          messageAr:
              'تعذر فتح الملف كقاعدة بيانات مشفّرة. تأكد أنه نسخة احتياطية من قيد وأن المفتاح لم يتغيّر.',
          code: 'backup_invalid',
        ),
      );
    }
  }
}
