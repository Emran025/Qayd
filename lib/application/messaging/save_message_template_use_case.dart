import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/message_template.dart';
import 'package:qayd/domain/repositories/message_template_repository.dart';

class SaveMessageTemplateUseCase {
  SaveMessageTemplateUseCase(this._repo);

  final MessageTemplateRepository _repo;

  Future<Result<void>> call(MessageTemplate template) => _repo.upsert(template);
}
