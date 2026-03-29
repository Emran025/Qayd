import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_output.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

class CreateVoucherUseCase {
  CreateVoucherUseCase(
    this._voucherRepository,
    this._currencyRepository,
    this._idGenerator,
    this._writeGuard,
  );

  final VoucherRepository _voucherRepository;
  final CurrencyRepository _currencyRepository;
  final IdGenerator _idGenerator;
  final GovernanceWriteGuard _writeGuard;

  Future<Result<CreateVoucherOutput>> call(CreateVoucherInput input) async {
    try {
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }
      final currencyRes = await _currencyRepository.getByCode(input.currencyCode);
      if (currencyRes.isFailure || currencyRes.valueOrNull == null) {
        return FailureResult(ValidationFailure(
          messageAr: 'العملة المختارة غير صالحة.',
          code: 'invalid_currency',
        ));
      }
      final currency = currencyRes.valueOrNull!;
      final amount = Money.positiveAmount(input.amountMinorUnits, currency);
      final voucher = Voucher.draft(
        id: VoucherId(_idGenerator.next()),
        type: input.type,
        date: input.date,
        amount: amount,
        currency: currency,
        counterpartyId: AccountId(input.counterpartyAccountId),
        affectedAccountId: AccountId(input.affectedAccountId),
        createdAt: DateTime.now(),
        referenceNumber: input.referenceNumber,
        description: input.description,
        notes: input.notes,
      );
      final saved = await _voucherRepository.save(voucher);
      return saved.fold(
        (f) => FailureResult(f),
        (_) => Success(
          CreateVoucherOutput(
            voucherId: voucher.id.value,
            stateCode: 'draft',
          ),
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
