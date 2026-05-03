import 'dart:convert';

import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/collateral.dart';
import 'package:qayd/domain/entities/collateral_revaluation.dart';
import 'package:qayd/domain/repositories/collateral_repository.dart';
import 'package:qayd/domain/value_objects/attachment_id.dart';
import 'package:qayd/domain/value_objects/attachment_ref.dart';
import 'package:qayd/domain/value_objects/attachment_source_type.dart';
import 'package:qayd/domain/value_objects/collateral_id.dart';
import 'package:qayd/domain/value_objects/collateral_status.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


/// SQLite-backed implementation of [CollateralRepository].
final class SqliteCollateralRepository implements CollateralRepository {
  SqliteCollateralRepository(this._db);

  final Database _db;

  static const _table = 'collaterals';
  static const _revalTable = 'collateral_revaluations';

  @override
  Future<Result<Collateral?>> getByVoucherId(VoucherId voucherId) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'voucher_id = ?',
        whereArgs: [voucherId.value],
        limit: 1,
      );
      if (rows.isEmpty) return const Success(null);
      return Success(_fromRow(rows.first));
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.failedToDownloadMortgage),
      );
    }
  }

  @override
  Future<Result<Collateral>> getById(CollateralId id) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'id = ?',
        whereArgs: [id.value],
        limit: 1,
      );
      if (rows.isEmpty) {
        return FailureResult(
          DatabaseFailure(messageAr: AppStringsAr.theMortgageDoesNot),
        );
      }
      return Success(_fromRow(rows.first));
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.failedToChargeMortgage),
      );
    }
  }

  @override
  Future<Result<void>> save(Collateral collateral) async {
    try {
      await _db.insert(
        _table,
        _toRow(collateral),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.failureToSaveThe),
      );
    }
  }

  @override
  Future<Result<void>> update(Collateral collateral) async {
    try {
      await _db.update(
        _table,
        _toRow(collateral),
        where: 'id = ?',
        whereArgs: [collateral.id.value],
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.failedToUpdateMortgage),
      );
    }
  }

  @override
  Future<Result<List<Collateral>>> listExpiring({
    required Duration within,
  }) async {
    try {
      final threshold = DateTime.now().add(within).toIso8601String();
      final now = DateTime.now().toIso8601String();
      final rows = await _db.query(
        _table,
        where: 'status = ? AND expiry_date IS NOT NULL '
            'AND expiry_date <= ? AND expiry_date >= ?',
        whereArgs: ['active', threshold, now],
        orderBy: 'expiry_date ASC',
      );
      return Success(rows.map(_fromRow).toList());
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.failedToInquireAbout),
      );
    }
  }

  @override
  Future<Result<List<Collateral>>> listByStatus(
    CollateralStatus status,
  ) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'status = ?',
        whereArgs: [status.name],
        orderBy: 'created_at DESC',
      );
      return Success(rows.map(_fromRow).toList());
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.failedToLoadMortgages),
      );
    }
  }

  // ── Audit Trail ─────────────────────────────────────────────────────────

  @override
  Future<Result<void>> saveRevaluation(CollateralRevaluation entry) async {
    try {
      await _db.insert(_revalTable, _revalToRow(entry));
      return const Success(null);
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.failedToSaveRevaluation),
      );
    }
  }

  @override
  Future<Result<List<CollateralRevaluation>>> getRevaluationHistory(
    CollateralId id,
  ) async {
    try {
      final rows = await _db.query(
        _revalTable,
        where: 'collateral_id = ?',
        whereArgs: [id.value],
        orderBy: 'evaluated_at ASC',
      );
      return Success(rows.map(_revalFromRow).toList());
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.failedToLoadRevaluation),
      );
    }
  }

  @override
  Future<Result<Set<String>>> getVoucherIdsWithCollateral(
      List<VoucherId> voucherIds) async {
    if (voucherIds.isEmpty) return const Success({});
    try {
      final placeholders = List.filled(voucherIds.length, '?').join(',');
      final rows = await _db.query(
        _table,
        columns: ['voucher_id'],
        where: 'voucher_id IN ($placeholders)',
        whereArgs: voucherIds.map((v) => v.value).toList(),
      );
      return Success(rows.map((r) => r['voucher_id'] as String).toSet());
    } catch (e) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStringsAr.failureToInspectMortgages),
      );
    }
  }

  // ── Mapping helpers ─────────────────────────────────────────────────────

  Map<String, dynamic> _toRow(Collateral c) {
    final imagesJson = c.imageRefs.isNotEmpty
        ? jsonEncode(c.imageRefs
            .map((r) => {
                  'id': r.id.value,
                  'path': r.storagePath,
                  if (r.mimeType != null) 'mimeType': r.mimeType,
                  if (r.byteSize != null) 'byteSize': r.byteSize,
                  if (r.encryptedBlobHash != null)
                    'blobHash': r.encryptedBlobHash,
                  if (r.thumbnailPath != null) 'thumbPath': r.thumbnailPath,
                  'source': r.sourceType.name,
                })
            .toList())
        : null;

    return {
      'id': c.id.value,
      'voucher_id': c.voucherId.value,
      'description': c.description,
      'estimated_value_minor': c.estimatedValue.minorUnits,
      'currency_code': c.currency.code,
      'status': c.status.name,
      'expiry_date': c.expiryDate?.toIso8601String(),
      'images_json': imagesJson,
      'encrypted_metadata': c.encryptedMetadata,
      'created_at': c.createdAt.toIso8601String(),
      'updated_at': c.updatedAt.toIso8601String(),
    };
  }

  Collateral _fromRow(Map<String, dynamic> row) {
    final code = row['currency_code'] as String;
    // When restoring from the local DB we only have the currency code string.
    // The full CurrencyCode (with nameAr/symbol) is resolved at the use-case
    // layer. Here we use a lightweight placeholder so the entity can be
    // constructed without requiring a repository call.
    final currencyCode = CurrencyCode(
      code: code,
      nameAr: code,
      symbol: code,
    );

    final imagesRaw = row['images_json'] as String?;
    final imageRefs = <AttachmentRef>[];
    if (imagesRaw != null && imagesRaw.isNotEmpty) {
      final list = jsonDecode(imagesRaw) as List<dynamic>;
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        imageRefs.add(AttachmentRef(
          id: AttachmentId(m['id'] as String),
          storagePath: m['path'] as String,
          mimeType: m['mimeType'] as String?,
          byteSize: m['byteSize'] as int?,
          encryptedBlobHash: m['blobHash'] as String?,
          thumbnailPath: m['thumbPath'] as String?,
          sourceType: AttachmentSourceType.fromString(
            m['source'] as String? ?? 'gallery',
          ),
        ));
      }
    }

    return Collateral(
      id: CollateralId(row['id'] as String),
      voucherId: VoucherId(row['voucher_id'] as String),
      description: row['description'] as String,
      estimatedValue: Money.positiveAmount(
        row['estimated_value_minor'] as int,
        currencyCode,
      ),
      currency: currencyCode,
      status: CollateralStatus.fromString(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      expiryDate: row['expiry_date'] != null
          ? DateTime.parse(row['expiry_date'] as String)
          : null,
      imageRefs: imageRefs,
      encryptedMetadata: row['encrypted_metadata'] as String?,
    );
  }

  Map<String, dynamic> _revalToRow(CollateralRevaluation r) => {
        'id': r.id,
        'collateral_id': r.collateralId.value,
        'old_value_minor': r.oldValueMinor,
        'new_value_minor': r.newValueMinor,
        'old_expiry_date': r.oldExpiryDate?.toIso8601String(),
        'new_expiry_date': r.newExpiryDate?.toIso8601String(),
        'reason': r.reason,
        'evaluated_at': r.evaluatedAt.toIso8601String(),
      };

  CollateralRevaluation _revalFromRow(Map<String, dynamic> row) =>
      CollateralRevaluation(
        id: row['id'] as String,
        collateralId: CollateralId(row['collateral_id'] as String),
        oldValueMinor: row['old_value_minor'] as int,
        newValueMinor: row['new_value_minor'] as int,
        oldExpiryDate: row['old_expiry_date'] != null
            ? DateTime.parse(row['old_expiry_date'] as String)
            : null,
        newExpiryDate: row['new_expiry_date'] != null
            ? DateTime.parse(row['new_expiry_date'] as String)
            : null,
        reason: row['reason'] as String,
        evaluatedAt: DateTime.parse(row['evaluated_at'] as String),
      );
}
