import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/message_template_repository.dart';

class DeleteMessageTemplateUseCase {
  DeleteMessageTemplateUseCase(this._repo);

  final MessageTemplateRepository _repo;

  Future<Result<void>> call(String templateId) => _repo.deleteById(templateId);
}
