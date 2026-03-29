import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/message_template.dart';
import 'package:qayd/domain/repositories/message_template_repository.dart';

class ListMessageTemplatesUseCase {
  ListMessageTemplatesUseCase(this._repo);

  final MessageTemplateRepository _repo;

  Future<Result<List<MessageTemplate>>> call() => _repo.getAll();
}
