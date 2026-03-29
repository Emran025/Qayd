import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/messaging/delete_message_template_use_case.dart';
import 'package:qayd/application/messaging/list_message_templates_use_case.dart';
import 'package:qayd/application/messaging/save_message_template_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/message_template.dart';
import 'package:qayd/presentation/pages/messaging/template_list_state.dart';

class TemplateListCubit extends Cubit<TemplateListState> {
  TemplateListCubit(
    this._list,
    this._save,
    this._delete,
  ) : super(const TemplateListLoading());

  final ListMessageTemplatesUseCase _list;
  final SaveMessageTemplateUseCase _save;
  final DeleteMessageTemplateUseCase _delete;

  Future<void> load() async {
    emit(const TemplateListLoading());
    final r = await _list();
    r.fold(
      (f) => emit(TemplateListFailure(f)),
      (list) => emit(TemplateListReady(list)),
    );
  }

  Future<Result<void>> saveTemplate(MessageTemplate updated) async {
    final r = await _save(updated);
    if (r.isSuccess) {
      await load();
    }
    return r;
  }

  Future<Result<void>> deleteTemplate(String id) async {
    final r = await _delete(id);
    if (r.isSuccess) {
      await load();
    }
    return r;
  }
}
