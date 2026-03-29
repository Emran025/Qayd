import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/mappers/currency_mapper.dart';
import 'package:qayd/data/models/currency_model.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

final class SqliteCurrencyRepository implements CurrencyRepository {
  SqliteCurrencyRepository(this._db);

  final Database _db;

  @override
  Future<Result<List<CurrencyCode>>> getAll() async {
    try {
      final maps = await _db.query('currencies', orderBy: 'is_predefined DESC, code ASC');
      final list = maps.map((m) => CurrencyMapper.toEntity(CurrencyModel.fromMap(m))).toList();
      return Success(list);
    } catch (e) {
      return FailureResult(DatabaseFailure(messageAr: 'فشل تحميل العملات: $e'));
    }
  }

  @override
  Future<Result<CurrencyCode?>> getByCode(String code) async {
    try {
      final maps = await _db.query(
        'currencies',
        where: 'code = ?',
        whereArgs: [code],
        limit: 1,
      );
      if (maps.isEmpty) return const Success(null);
      return Success(CurrencyMapper.toEntity(CurrencyModel.fromMap(maps.first)));
    } catch (e) {
      return FailureResult(DatabaseFailure(messageAr: 'فشل تحميل العملة: $e'));
    }
  }

  @override
  Future<Result<void>> save(CurrencyCode currency, {bool isPredefined = false}) async {
    try {
      final model = CurrencyMapper.toModel(currency, isPredefined: isPredefined);
      await _db.insert(
        'currencies',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(DatabaseFailure(messageAr: 'فشل حفظ العملة: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String code) async {
    try {
      // Check if code is in use in vouchers or entries
      final voucherCount = Sqflite.firstIntValue(await _db.rawQuery(
        'SELECT COUNT(*) FROM vouchers WHERE currency_code = ?',
        [code],
      ));
      if ((voucherCount ?? 0) > 0) {
        return FailureResult(DatabaseFailure(messageAr: 'لا يمكن حذف العملة لأنها مستخدمة في سندات.'));
      }

      await _db.delete(
        'currencies',
        where: 'code = ? AND is_predefined = 0',
        whereArgs: [code],
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(DatabaseFailure(messageAr: 'فشل حذف العملة: $e'));
    }
  }

  @override
  Future<Result<String>> getBaseCurrencyCode() async {
    try {
      final maps = await _db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['base_currency_code'],
        limit: 1,
      );
      if (maps.isEmpty) return const Success('SAR');
      return Success(maps.first['value']! as String);
    } catch (e) {
      return const Success('SAR'); // Fallback to SAR
    }
  }

  @override
  Future<Result<void>> setBaseCurrencyCode(String code) async {
    try {
      await _db.insert(
        'app_settings',
        {'key': 'base_currency_code', 'value': code},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(DatabaseFailure(messageAr: 'فشل حفظ العملة الأساسية: $e'));
    }
  }
}
