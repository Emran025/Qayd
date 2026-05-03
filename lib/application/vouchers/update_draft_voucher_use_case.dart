import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/application/vouchers/dtos/update_draft_voucher_input.dart';
import 'package:qayd/application/vouchers/dtos/update_draft_voucher_output.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


class UpdateDraftVoucherUseCase {
  UpdateDraftVoucherUseCase(
    this._voucherRepository,
    this._currencyRepository,
    this._writeGuard,
  );

  final VoucherRepository _voucherRepository;
  final CurrencyRepository _currencyRepository;
  final GovernanceWriteGuard _writeGuard;

  Future<Result<UpdateDraftVoucherOutput>> call(
      UpdateDraftVoucherInput input) async {
    try {
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }
      final loaded =
          await _voucherRepository.getById(VoucherId(input.voucherId));
      if (loaded.isFailure) {
        return FailureResult(loaded.failureOrNull!);
      }
      final current = loaded.valueOrNull!;

      CurrencyCode? currency;
      if (input.currencyCode != null) {
        final currencyRes =
            await _currencyRepository.getByCode(input.currencyCode!);
        if (currencyRes.isFailure || currencyRes.valueOrNull == null) {
          return FailureResult(ValidationFailure(
            messageAr: AppStringsAr.theSelectedCurrencyIs,
            code: 'invalid_currency',
          ));
        }
        currency = currencyRes.valueOrNull!;
      }

      Money? amount;
      if (input.amountMinorUnits != null) {
        // Use either the new currency or the current voucher's currency
        final activeCurrency = currency ?? current.currency;
        amount = Money.positiveAmount(input.amountMinorUnits!, activeCurrency);
      }

      final updated = current.updateDraft(
        type: input.type,
        date: input.date,
        amount: amount,
        currency: currency,
        counterpartyId: input.counterpartyAccountId != null
            ? AccountId(input.counterpartyAccountId!)
            : null,
        affectedAccountId: input.affectedAccountId != null
            ? AccountId(input.affectedAccountId!)
            : null,
        referenceNumber: input.referenceNumber,
        description: input.description,
        notes: input.notes,
      );
      final saved = await _voucherRepository.save(updated);
      return saved.fold(
        (f) => FailureResult(f),
        (_) => Success(
          UpdateDraftVoucherOutput(
            voucherId: updated.id.value,
            stateCode: updated.state.name,
          ),
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
