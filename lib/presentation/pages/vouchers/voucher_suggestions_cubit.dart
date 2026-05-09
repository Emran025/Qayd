import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/suggestions/get_auto_suggestions_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/suggestions/mark_notification_message_processed_use_case.dart';
import 'package:qayd/application/suggestions/scored_suggestion_dto.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

sealed class VoucherSuggestionsState {
  const VoucherSuggestionsState();
}

final class VoucherSuggestionsInitial extends VoucherSuggestionsState {
  const VoucherSuggestionsInitial();
}

final class VoucherSuggestionsLoading extends VoucherSuggestionsState {
  const VoucherSuggestionsLoading();
}

final class VoucherSuggestionsEmpty extends VoucherSuggestionsState {
  const VoucherSuggestionsEmpty();
}

final class VoucherSuggestionsReady extends VoucherSuggestionsState {
  const VoucherSuggestionsReady(this.suggestions);

  final List<ScoredSuggestionDto> suggestions;
}

final class VoucherSuggestionsError extends VoucherSuggestionsState {
  const VoucherSuggestionsError(this.messageAr);

  final String messageAr;
}

/// Emitted once when user accepts a suggestion (form should apply + animate).
final class VoucherSuggestionsApplied extends VoucherSuggestionsState {
  const VoucherSuggestionsApplied({
    required this.amountMinorUnits,
    required this.date,
    required this.type,
    required this.messageId,
  });

  final int? amountMinorUnits;
  final DateTime? date;
  final VoucherType? type;
  final String messageId;
}

class VoucherSuggestionsCubit extends Cubit<VoucherSuggestionsState> {
  VoucherSuggestionsCubit(
    this._getSuggestions,
    this._markProcessed,
  ) : super(const VoucherSuggestionsInitial());

  final GetAutoSuggestionsUseCase _getSuggestions;
  final MarkNotificationMessageProcessedUseCase _markProcessed;

  Future<void> loadForCounterparty(String? counterpartyAccountId) async {
    if (counterpartyAccountId == null || counterpartyAccountId.isEmpty) {
      emit(const VoucherSuggestionsEmpty());
      return;
    }
    emit(const VoucherSuggestionsLoading());
    final r = await _getSuggestions(counterpartyAccountId);
    if (isClosed) return;
    if (r.isFailure) {
      emit(VoucherSuggestionsError(r.failureOrNull!.messageAr));
      return;
    }
    final list = r.valueOrNull!;
    if (list.isEmpty) {
      emit(const VoucherSuggestionsEmpty());
    } else {
      emit(VoucherSuggestionsReady(list));
    }
  }

  Future<void> acceptAndMarkProcessed(ScoredSuggestionDto s) async {
    if (!s.messageId.startsWith('freq_')) {
      final mr = await _markProcessed(s.messageId);
      if (isClosed) return;
      if (mr.isFailure) {
        emit(VoucherSuggestionsError(mr.failureOrNull!.messageAr));
        return;
      }
    }
    emit(
      VoucherSuggestionsApplied(
        amountMinorUnits: s.amountMinorUnits,
        date: s.date,
        type: s.type,
        messageId: s.messageId,
      ),
    );
  }
}
