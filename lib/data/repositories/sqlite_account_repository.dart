import 'dart:convert';

import 'package:qayd/application/accounts/dtos/account_default_cost_center_dto.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/mappers/account_mapper.dart';
import 'package:qayd/data/models/account_model.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/entities/party_details.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


final class SqliteAccountRepository implements AccountRepository {
  SqliteAccountRepository(this._db);

  final Database _db;

  static const _table = 'accounts';

  @override
  Future<Result<Account>> getById(AccountId id) async {
    try {
      final rows = await _db.rawQuery(
        '''
        SELECT a.*, p.phone_number, p.whatsapp_number
        FROM $_table a
        LEFT JOIN party_details p ON a.id = p.account_id
        WHERE a.id = ?
        LIMIT 1
        ''',
        [id.value],
      );
      if (rows.isEmpty) {
        return  FailureResult(
          ValidationFailure(
            messageAr: AppStrings.theAccountDoesNot,
            code: 'account_not_found',
          ),
        );
      }
      final row = rows.first;
      final model = AccountModel.fromMap(row);
      var entity = AccountMapper.toEntity(model);

      final phone = row['phone_number'] as String?;
      final whatsapp = row['whatsapp_number'] as String?;
      if (phone != null || whatsapp != null) {
        entity = entity.updateMetadata({
          if (phone != null) 'phone': phone,
          if (whatsapp != null) 'whatsapp': whatsapp,
        });
      }

      return Success(entity);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.theAccountCouldNot1),
      );
    }
  }

  @override
  Future<Result<List<Account>>> getAll({
    bool activeOnly = false,
    bool excludeArchived = false,
  }) async {
    try {
      final conditions = <String>[];
      if (activeOnly) conditions.add('a.is_active = 1');
      if (excludeArchived) conditions.add('a.is_archived = 0');

      final whereClause = conditions.isEmpty ? null : conditions.join(' AND ');

      final rows = await _db.rawQuery(
        '''
        SELECT a.*, p.phone_number, p.whatsapp_number
        FROM $_table a
        LEFT JOIN party_details p ON a.id = p.account_id
        ${whereClause != null ? 'WHERE $whereClause' : ''}
        ORDER BY a.name COLLATE NOCASE
        ''',
      );

      return Success(
        rows.map((row) {
          final model = AccountModel.fromMap(row);
          final entity = AccountMapper.toEntity(model);

          // Inject phone/whatsapp into metadata for easy searching/display in UI
          final phone = row['phone_number'] as String?;
          final whatsapp = row['whatsapp_number'] as String?;

          if (phone != null || whatsapp != null) {
            return entity.updateMetadata({
              if (phone != null) 'phone': phone,
              if (whatsapp != null) 'whatsapp': whatsapp,
            });
          }
          return entity;
        }).toList(growable: false),
      );
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToReadThe),
      );
    }
  }

  @override
  Future<Result<List<Account>>> getChildrenOf(AccountId parentId) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'parent_id = ?',
        whereArgs: [parentId.value],
        orderBy: 'name COLLATE NOCASE',
      );
      return Success(
        rows
            .map((m) => AccountMapper.toEntity(AccountModel.fromMap(m)))
            .toList(growable: false),
      );
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToReadSubaccounts),
      );
    }
  }

  @override
  Future<Result<List<Account>>> getDescendantsOf(AccountId parentId) async {
    try {
      final rows = await _db.rawQuery(
        '''
WITH RECURSIVE descendants AS (
  SELECT id FROM $_table WHERE parent_id = ?
  UNION ALL
  SELECT a.id FROM $_table a
  INNER JOIN descendants d ON a.parent_id = d.id
)
SELECT a.* FROM $_table a
WHERE a.id IN (SELECT id FROM descendants)
ORDER BY a.name COLLATE NOCASE
''',
        [parentId.value],
      );
      return Success(
        rows
            .map((m) => AccountMapper.toEntity(AccountModel.fromMap(m)))
            .toList(growable: false),
      );
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToReadDependent),
      );
    }
  }

  @override
  Future<Result<void>> save(Account account) async {
    try {
      final map = AccountMapper.toModel(account).toMap();
      // Use update instead of replace to avoid breaking foreign key constraints
      // (REPLACE is actually DELETE + INSERT in SQLite).
      final rowsAffected = await _db.update(
        _table,
        map,
        where: 'id = ?',
        whereArgs: [account.id.value],
      );

      if (rowsAffected == 0) {
        await _db.insert(_table, map);
      }

      return  Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToSaveAccount),
      );
    }
  }

  @override
  Future<Result<void>> createBatch(List<Account> accounts) async {
    try {
      await _db.transaction((txn) async {
        for (final a in accounts) {
          final map = AccountMapper.toModel(a).toMap();
          await txn.insert(
            _table,
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      return  Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.accountsCouldNotBe),
      );
    }
  }

  @override
  Future<Result<void>> delete(AccountId id) async {
    try {
      final n = await _db.delete(
        _table,
        where: 'id = ?',
        whereArgs: [id.value],
      );
      if (n == 0) {
        return  FailureResult(
          ValidationFailure(
            messageAr: AppStrings.theAccountDoesNot,
            code: 'account_not_found',
          ),
        );
      }
      return  Success(null);
    } on DatabaseException {
      return  FailureResult(
        DatabaseFailure(
          messageAr: AppStrings.unableToDeleteAccount,
        ),
      );
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToDeleteAccount1),
      );
    }
  }

  @override
  Future<Result<bool>> exists(AccountId id) async {
    try {
      final rows = await _db.rawQuery(
        'SELECT 1 FROM $_table WHERE id = ? LIMIT 1',
        [id.value],
      );
      return Success(rows.isNotEmpty);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToVerifyAccount),
      );
    }
  }

  @override
  Future<Result<void>> savePartyDetails(PartyDetails details) async {
    try {
      final map = {
        'account_id': details.accountId.value,
        'phone_number': details.phoneNumber,
        'email': details.email,
        'whatsapp_number': details.whatsappNumber,
        'bank_account_info': details.bankAccountInfo,
        'party_type': details.partyType,
        'current_public_key_hex': details.currentPublicKeyHex,
        'public_key_history_json':
            _encodeKeyHistory(details.publicKeyHistoryHex),
        'server_account_id': details.serverAccountId,
      };
      final rowsAffected = await _db.update(
        'party_details',
        map,
        where: 'account_id = ?',
        whereArgs: [details.accountId.value],
      );

      if (rowsAffected == 0) {
        await _db.insert('party_details', map);
      }
      return  Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.thePartyDataCould),
      );
    }
  }

  @override
  Future<Result<PartyDetails?>> getPartyDetails(AccountId id) async {
    try {
      final rows = await _db.query(
        'party_details',
        where: 'account_id = ?',
        whereArgs: [id.value],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const Success(null);
      }
      final row = rows.first;
      return Success(PartyDetails(
        accountId: id,
        phoneNumber: row['phone_number'] as String?,
        email: row['email'] as String?,
        whatsappNumber: row['whatsapp_number'] as String?,
        bankAccountInfo: row['bank_account_info'] as String?,
        partyType: row['party_type'] as String?,
        currentPublicKeyHex: row['current_public_key_hex'] as String?,
        publicKeyHistoryHex: _decodeKeyHistory(
          row['public_key_history_json'] as String?,
        ),
        serverAccountId: row['server_account_id'] as int?,
      ));
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.thePartyDataCould1),
      );
    }
  }

  @override
  Future<Result<AccountId?>> findAccountByPhone(String phone) async {
    try {
      final rows = await _db.query(
        'party_details',
        where: 'phone_number = ?',
        whereArgs: [phone],
        limit: 1,
      );
      if (rows.isEmpty) {
        return  Success(null);
      }
      return Success(AccountId(rows.first['account_id'] as String));
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToSearchBy),
      );
    }
  }

  @override
  Future<Result<AccountId?>> findAccountByEmail(String email) async {
    try {
      final rows = await _db.query(
        'party_details',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      if (rows.isEmpty) {
        return  Success(null);
      }
      return Success(AccountId(rows.first['account_id'] as String));
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToSearchBy1),
      );
    }
  }

  @override
  Future<Result<AccountId?>> findAccountByWhatsApp(String whatsapp) async {
    try {
      final rows = await _db.query(
        'party_details',
        where: 'whatsapp_number = ?',
        whereArgs: [whatsapp],
        limit: 1,
      );
      if (rows.isEmpty) {
        return  Success(null);
      }
      return Success(AccountId(rows.first['account_id'] as String));
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToSearchBy2),
      );
    }
  }

  @override
  Future<Result<bool>> hasAnyAccounts() async {
    try {
      final rows = await _db.rawQuery('SELECT 1 FROM $_table LIMIT 1');
      return Success(rows.isNotEmpty);
    } catch (_) {
      return const Success(false);
    }
  }

  // ── Archive operations ──────────────────────────────────────────────────

  @override
  Future<Result<void>> archiveAccount(AccountId id) async {
    try {
      final n = await _db.update(
        _table,
        {'is_archived': 1},
        where: 'id = ?',
        whereArgs: [id.value],
      );
      if (n == 0) {
        return  FailureResult(
          ValidationFailure(
            messageAr: AppStrings.theAccountDoesNot,
            code: 'account_not_found',
          ),
        );
      }
      return  Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.theAccountCouldNot),
      );
    }
  }

  @override
  Future<Result<void>> restoreAccount(AccountId id) async {
    try {
      final n = await _db.update(
        _table,
        {'is_archived': 0},
        where: 'id = ?',
        whereArgs: [id.value],
      );
      if (n == 0) {
        return  FailureResult(
          ValidationFailure(
            messageAr: AppStrings.theAccountDoesNot,
            code: 'account_not_found',
          ),
        );
      }
      return  Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToRestoreAccount),
      );
    }
  }

  @override
  Future<Result<List<Account>>> getArchivedAccounts() async {
    try {
      final rows = await _db.query(
        _table,
        where: 'is_archived = 1',
        orderBy: 'name COLLATE NOCASE',
      );
      return Success(
        rows
            .map((m) => AccountMapper.toEntity(AccountModel.fromMap(m)))
            .toList(growable: false),
      );
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToReadArchived),
      );
    }
  }

  // ── Default Cost Centers ──────────────────────────────────────────────────

  static const _adcc = 'account_default_cost_centers';

  @override
  Future<Result<List<AccountDefaultCostCenterDto>>> getDefaultCostCenters(
    AccountId accountId,
  ) async {
    try {
      final rows = await _db.rawQuery(
        '''
SELECT a.id, a.account_id, a.cost_center_id, a.dimension_ids_json,
       c.name AS center_name
FROM $_adcc a
LEFT JOIN cost_centers c ON c.id = a.cost_center_id
WHERE a.account_id = ?
ORDER BY a.created_at
''',
        [accountId.value],
      );
      return Success(rows.map(_adccFromRow).toList(growable: false));
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(
          messageAr: AppStrings.theDefaultCostCenters,
        ),
      );
    }
  }

  @override
  Future<Result<void>> saveDefaultCostCenter({
    required AccountId accountId,
    required String costCenterId,
    required List<String> dimensionIds,
  }) async {
    try {
      // Try to find existing row first (for upsert)
      final existing = await _db.query(
        _adcc,
        where: 'account_id = ? AND cost_center_id = ?',
        whereArgs: [accountId.value, costCenterId],
        limit: 1,
      );
      final now = DateTime.now().toIso8601String();
      final dimsJson = jsonEncode(dimensionIds);
      if (existing.isEmpty) {
        await _db.insert(_adcc, {
          'id': _adccUuid(),
          'account_id': accountId.value,
          'cost_center_id': costCenterId,
          'dimension_ids_json': dimsJson,
          'created_at': now,
        });
      } else {
        await _db.update(
          _adcc,
          {'dimension_ids_json': dimsJson},
          where: 'account_id = ? AND cost_center_id = ?',
          whereArgs: [accountId.value, costCenterId],
        );
      }
      return const Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(
          messageAr: AppStrings.theDefaultCostCenter,
        ),
      );
    }
  }

  @override
  Future<Result<void>> removeDefaultCostCenter({
    required AccountId accountId,
    required String costCenterId,
  }) async {
    try {
      await _db.delete(
        _adcc,
        where: 'account_id = ? AND cost_center_id = ?',
        whereArgs: [accountId.value, costCenterId],
      );
      return const Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(
          messageAr: AppStrings.theDefaultCostCenter2,
        ),
      );
    }
  }

  static AccountDefaultCostCenterDto _adccFromRow(Map<String, Object?> r) {
    final dimsJson = r['dimension_ids_json'] as String? ?? '[]';
    List<String> dims = const [];
    try {
      dims = (jsonDecode(dimsJson) as List<dynamic>)
          .map((e) => e as String)
          .toList();
    } catch (_) {}
    return AccountDefaultCostCenterDto(
      id: r['id'] as String,
      accountId: r['account_id'] as String,
      costCenterId: r['cost_center_id'] as String,
      costCenterName: r['center_name'] as String?,
      dimensionIds: dims,
    );
  }

  static String _adccUuid() {
    // Lightweight UUID v4 without external dependency
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(16).padLeft(12, '0')}-'
        '${(now >> 16).toRadixString(16).padLeft(4, '0')}-'
        '4${(now >> 20).toRadixString(16).padLeft(3, '0')}-'
        '${((now >> 24) | 0x8000).toRadixString(16).padLeft(4, '0')}-'
        '${(now * 37).toRadixString(16).padLeft(12, '0').substring(0, 12)}';
  }

  // ── JSON helpers for public key history ──────────────────────────────────

  static String _encodeKeyHistory(List<String> keys) {
    return jsonEncode(keys);
  }

  static List<String> _decodeKeyHistory(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.map((e) => e as String).toList();
    } catch (_) {
      return const [];
    }
  }
}
