import 'package:qayd/application/suggestions/auto_suggestion_engine.dart';
import 'package:qayd/application/suggestions/scored_suggestion_dto.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';

final class GetAutoSuggestionsUseCase {
  GetAutoSuggestionsUseCase(this._repo);

  final NotificationMessageRepository _repo;

  Future<Result<List<ScoredSuggestionDto>>> call(String counterpartyAccountId) async {
    final r = await _repo.listUnprocessedForCounterparty(
      counterpartyAccountId: counterpartyAccountId,
      limit: 50,
    );
    if (r.isFailure) {
      return FailureResult(r.failureOrNull!);
    }
    final list = AutoSuggestionEngine.build(r.valueOrNull!, DateTime.now());
    return Success(list);
  }
}
