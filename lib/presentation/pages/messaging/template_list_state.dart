import 'package:qayd/core/error/failures.dart';
import 'package:qayd/domain/entities/message_template.dart';

sealed class TemplateListState {
  const TemplateListState();
}

final class TemplateListLoading extends TemplateListState {
  const TemplateListLoading();
}

final class TemplateListReady extends TemplateListState {
  const TemplateListReady(this.templates);

  final List<MessageTemplate> templates;
}

final class TemplateListFailure extends TemplateListState {
  const TemplateListFailure(this.failure);

  final Failure failure;
}
