import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/transaction_fee_setting.dart';
import 'package:qayd/domain/repositories/transaction_fee_settings_repository.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class SqliteTransactionFeeSettingsRepository
    implements TransactionFeeSettingsRepository {
  SqliteTransactionFeeSettingsRepository(this._db);

  final Database _db;

  @override
  Future<Result<TransactionFeeSetting?>> getActive() async {
    try {
      final rows = await _db.query(
        'transaction_fees',
        where: 'is_active = 1',
        limit: 1,
      );

      if (rows.isEmpty) {
        return const Success(null);
      }

      final row = rows.first;
      final setting = TransactionFeeSetting(
        id: row['id'] as String,
        amountMinorUnits: row['amount_minor_units'] as int,
        currencyCode: row['currency_code'] as String,
        isActive: (row['is_active'] as int) == 1,
        createdAt: DateTime.parse(row['created_at'] as String),
      );

      return Success(setting);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: 'فشل في الحصول على رسوم التحويل النشطة: \$e'),
      );
    }
  }

  @override
  Future<Result<void>> insert(TransactionFeeSetting setting) async {
    try {
      await _db.insert('transaction_fees', {
        'id': setting.id,
        'amount_minor_units': setting.amountMinorUnits,
        'currency_code': setting.currencyCode,
        'is_active': setting.isActive ? 1 : 0,
        'created_at': setting.createdAt.toIso8601String(),
      });
      return const Success(null);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: 'فشل في إدراج رسوم التحويل: \$e'),
      );
    }
  }

  @override
  Future<Result<void>> deactivateAll() async {
    try {
      await _db.update('transaction_fees', {'is_active': 0});
      return const Success(null);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: 'فشل في إلغاء تفعيل رسوم التحويل: \$e'),
      );
    }
  }
}
