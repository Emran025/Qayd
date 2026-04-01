import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/application/vouchers/dtos/create_tripartite_transfer_input.dart';
import 'package:qayd/application/vouchers/dtos/create_tripartite_transfer_output.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/tripartite_meta.dart';
import 'package:qayd/domain/value_objects/tripartite_role.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

/// Creates a tripartite intermediary transfer (A → Me → B).
///
/// Atomically persists two linked draft vouchers:
/// - **Receipt** (A → C): Cr Source, Dr MyAccount
/// - **Payment** (C → B): Dr Destination, Cr MyAccount — initially contingent
///
/// The payment voucher is locked (`isContingent = true`) until the receipt
/// voucher is confirmed, preventing premature fund disbursement.
class CreateTripartiteTransferUseCase {
  CreateTripartiteTransferUseCase(
    this._voucherRepository,
    this._currencyRepository,
    this._idGenerator,
    this._writeGuard,
  );

  final VoucherRepository _voucherRepository;
  final CurrencyRepository _currencyRepository;
  final IdGenerator _idGenerator;
  final GovernanceWriteGuard _writeGuard;

  Future<Result<CreateTripartiteTransferOutput>> call(
    CreateTripartiteTransferInput input,
  ) async {
    try {
      // 1. Governance gate
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }

      // 2. Validate currency
      final currencyRes =
          await _currencyRepository.getByCode(input.currencyCode);
      if (currencyRes.isFailure || currencyRes.valueOrNull == null) {
        return FailureResult(ValidationFailure(
          messageAr: 'العملة المختارة غير صالحة.',
          code: 'invalid_currency',
        ));
      }
      final currency = currencyRes.valueOrNull!;

      // 3. Validate parties are distinct
      final sourceId = AccountId(input.sourceAccountId);
      final destId = AccountId(input.destinationAccountId);
      final affectedId = AccountId(input.affectedAccountId);

      if (sourceId == destId) {
        return const FailureResult(ValidationFailure(
          messageAr: 'لا يمكن أن يكون المصدر والوجهة نفس الطرف.',
          code: 'tripartite_same_source_dest',
        ));
      }
      if (sourceId == affectedId || destId == affectedId) {
        return const FailureResult(ValidationFailure(
          messageAr:
              'الحساب الوسيط يجب أن يكون مختلفاً عن المصدر والوجهة.',
          code: 'tripartite_affected_conflict',
        ));
      }

      // 4. Generate shared identifiers
      final transferGroupId = _idGenerator.next();
      final receiptId = VoucherId(_idGenerator.next());
      final paymentId = VoucherId(_idGenerator.next());
      final now = DateTime.now();
      final amount = Money.positiveAmount(input.amountMinorUnits, currency);

      // 5. Create Receipt Voucher (A → C)
      // counterparty = Source (A), affectedAccount = MyAccount (C)
      // type = receipt (money coming IN from A)
      final receiptVoucher = Voucher.draft(
        id: receiptId,
        type: VoucherType.receipt,
        date: input.date,
        amount: amount,
        currency: currency,
        counterpartyId: sourceId,
        affectedAccountId: affectedId,
        createdAt: now,
        description: input.description,
        notes: input.notes,
        tripartiteMeta: TripartiteMeta(
          transferGroupId: transferGroupId,
          role: TripartiteRole.intermediaryReceipt,
          linkedPartyId: destId, // B is the linked party on the receipt
          isContingent: false, // receipt is immediately actionable
        ),
      );

      // 6. Create Payment Voucher (C → B) — contingent
      // counterparty = Destination (B), affectedAccount = MyAccount (C)
      // type = payment (money going OUT to B)
      final paymentVoucher = Voucher.draft(
        id: paymentId,
        type: VoucherType.payment,
        date: input.date,
        amount: amount,
        currency: currency,
        counterpartyId: destId,
        affectedAccountId: affectedId,
        createdAt: now,
        description: input.description,
        notes: input.notes,
        tripartiteMeta: TripartiteMeta(
          transferGroupId: transferGroupId,
          role: TripartiteRole.intermediaryPayment,
          linkedPartyId: sourceId, // A is the linked party on the payment
          isContingent: true, // locked until receipt is confirmed
        ),
      );

      // 7. Atomic persist
      final saveResult = await _voucherRepository.saveTripartitePair(
        receiptVoucher: receiptVoucher,
        paymentVoucher: paymentVoucher,
      );

      return saveResult.fold(
        (f) => FailureResult(f),
        (_) => Success(
          CreateTripartiteTransferOutput(
            receiptVoucherId: receiptId.value,
            paymentVoucherId: paymentId.value,
            transferGroupId: transferGroupId,
          ),
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
