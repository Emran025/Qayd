import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/message_template.dart';
import 'package:qayd/domain/value_objects/message_template_kind.dart';

abstract interface class MessageTemplateRepository {
  Future<Result<List<MessageTemplate>>> getAll();

  Future<Result<List<MessageTemplate>>> getByKind(MessageTemplateKind kind);

  Future<Result<MessageTemplate>> getById(String id);

  Future<Result<void>> upsert(MessageTemplate template);

  /// Allowed only when [MessageTemplate.isSystem] is false.
  Future<Result<void>> deleteById(String id);
}
