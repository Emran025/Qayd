import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/vouchers/dtos/list_vouchers_input.dart';
import 'package:qayd/application/vouchers/dtos/list_vouchers_output.dart';
import 'package:qayd/application/vouchers/dtos/voucher_summary_dto.dart';
import 'package:qayd/application/vouchers/voucher_filter_mapper.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';

class ListVouchersUseCase {
  ListVouchersUseCase(
    this._voucherRepository,
    this._accountRepository,
  );

  final VoucherRepository _voucherRepository;
  final AccountRepository _accountRepository;

  Future<Result<ListVouchersOutput>> call(ListVouchersInput input) async {
    try {
      final accountsR = await _accountRepository.getAll(activeOnly: false);
      if (accountsR.isFailure) {
        return FailureResult(accountsR.failureOrNull!);
      }
      final nameById = {
        for (final a in accountsR.valueOrNull!) a.id.value: a.name,
      };

      final domainFilter = VoucherFilterMapper.toDomain(input.advancedFilter);
      final q = input.searchQuery?.trim() ?? '';
      final Result<List<Voucher>> r = q.isEmpty
          ? await _voucherRepository.getAll(
              filter: domainFilter,
              limit: input.limit,
              offset: input.offset,
            )
          : await _voucherRepository.search(
              queryText: q,
              filter: domainFilter,
            );
      if (r.isFailure) {
        return FailureResult(r.failureOrNull!);
      }
      final list = r.valueOrNull!;
      return Success(
        ListVouchersOutput(
          accountNamesById: nameById,
          vouchers: list
              .map(
                (v) => VoucherSummaryDto(
                  id: v.id.value,
                  typeCode: v.type.name,
                  stateCode: v.state.name,
                  dateIso: v.date.toIso8601String(),
                  amountMinorUnits: v.amount.minorUnits,
                  currencyCode: v.currency.code,
                  currencyNameAr: v.currency.nameAr,
                  currencySymbol: v.currency.symbol,
                  currencyDigits: v.currency.fractionalDigits,
                  counterpartyAccountId: v.counterpartyId.value,
                  counterpartyName:
                      nameById[v.counterpartyId.value] ?? v.counterpartyId.value,
                  affectedAccountId: v.affectedAccountId.value,
                  affectedName:
                      nameById[v.affectedAccountId.value] ??
                      v.affectedAccountId.value,
                ),
              )
              .toList(growable: false),
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
