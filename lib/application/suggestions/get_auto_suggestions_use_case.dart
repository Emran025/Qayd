import 'package:qayd/application/suggestions/auto_suggestion_engine.dart';
import 'package:qayd/application/suggestions/scored_suggestion_dto.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';

final class GetAutoSuggestionsUseCase {
  GetAutoSuggestionsUseCase(this._repo, this._voucherRepo);

  final NotificationMessageRepository _repo;
  final VoucherRepository _voucherRepo;

  Future<Result<List<ScoredSuggestionDto>>> call(String counterpartyAccountId) async {
    final r = await _repo.listUnprocessedForCounterparty(
      counterpartyAccountId: counterpartyAccountId,
      limit: 50,
    );
    if (r.isFailure) {
      return FailureResult(r.failureOrNull!);
    }
    final list = AutoSuggestionEngine.build(r.valueOrNull!, DateTime.now());

    final vouchersRes = await _voucherRepo.getByCounterparty(
      AccountId(counterpartyAccountId),
    );
    if (vouchersRes.isSuccess) {
      final vouchers = vouchersRes.valueOrNull ?? [];
      final frequencyMap = <int, int>{};
      for (final v in vouchers) {
        final amount = v.amount.minorUnits;
        frequencyMap[amount] = (frequencyMap[amount] ?? 0) + 1;
      }
      
      final frequentAmounts = frequencyMap.entries
          .where((e) => e.value >= 2)
          .map((e) => e.key)
          .toList();

      for (final amount in frequentAmounts) {
        final hasExisting = list.any((s) => s.amountMinorUnits == amount);
        if (hasExisting) continue;

        final freqVouchers =
            vouchers.where((v) => v.amount.minorUnits == amount).toList();
        freqVouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final latest = freqVouchers.first;

        list.add(
          ScoredSuggestionDto(
            messageId: 'freq_$amount',
            rawBody: 'مبلغ متكرر',
            createdAt: DateTime.now(),
            score: 0.0,
            amountMinorUnits: amount,
            date: DateTime.now(),
            type: latest.type,
          ),
        );
      }
    }

    return Success(list);
  }
}
