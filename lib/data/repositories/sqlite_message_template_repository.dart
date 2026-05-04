import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/mappers/message_template_mapper.dart';
import 'package:qayd/data/models/message_template_model.dart';
import 'package:qayd/domain/entities/message_template.dart';
import 'package:qayd/domain/repositories/message_template_repository.dart';
import 'package:qayd/domain/value_objects/message_template_kind.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


final class SqliteMessageTemplateRepository
    implements MessageTemplateRepository {
  SqliteMessageTemplateRepository(this._db);

  final Database _db;

  static const _table = 'message_templates';

  @override
  Future<Result<List<MessageTemplate>>> getAll() async {
    try {
      final rows = await _db.query(
        _table,
        orderBy: 'kind ASC, sort_order ASC, name ASC',
      );
      return Success(
        rows
            .map((m) =>
                MessageTemplateMapper.toEntity(MessageTemplateModel.fromMap(m)))
            .toList(growable: false),
      );
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToReadMessage),
      );
    }
  }

  @override
  Future<Result<List<MessageTemplate>>> getByKind(
    MessageTemplateKind kind,
  ) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'kind = ?',
        whereArgs: [kind.storageCode],
        orderBy: 'sort_order ASC, name ASC',
      );
      return Success(
        rows
            .map((m) =>
                MessageTemplateMapper.toEntity(MessageTemplateModel.fromMap(m)))
            .toList(growable: false),
      );
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.unableToReadTemplates),
      );
    }
  }

  @override
  Future<Result<MessageTemplate>> getById(String id) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return  FailureResult(
          ValidationFailure(
            messageAr: AppStrings.templateNotFound,
            code: 'template_not_found',
          ),
        );
      }
      return Success(
        MessageTemplateMapper.toEntity(
            MessageTemplateModel.fromMap(rows.first)),
      );
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.theTemplateCouldNot2),
      );
    }
  }

  @override
  Future<Result<void>> upsert(MessageTemplate template) async {
    try {
      final map = MessageTemplateMapper.toModel(template).toMap();
      await _db.insert(
        _table,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return  Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.theTemplateCouldNot1),
      );
    }
  }

  @override
  Future<Result<void>> deleteById(String id) async {
    try {
      final rows = await _db.query(
        _table,
        columns: ['is_system'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return  FailureResult(
          ValidationFailure(
            messageAr: AppStrings.templateNotFound,
            code: 'template_not_found',
          ),
        );
      }
      if ((rows.first['is_system'] as int) != 0) {
        return  FailureResult(
          ValidationFailure(
            messageAr: AppStrings.theDefaultTemplateCannot,
            code: 'template_system_delete',
          ),
        );
      }
      await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
      return  Success(null);
    } catch (_) {
      return  FailureResult(
        DatabaseFailure(messageAr: AppStrings.theTemplateCouldNot),
      );
    }
  }
}
