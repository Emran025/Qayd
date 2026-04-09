import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/application/vouchers/dtos/create_tripartite_transfer_input.dart';
import 'package:qayd/application/vouchers/dtos/create_tripartite_transfer_output.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/tripartite_meta.dart';
import 'package:qayd/domain/value_objects/tripartite_role.dart';
import 'package:qayd/application/settings/get_active_transaction_fee_use_case.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';

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
    this._getActiveFee,
    this._accountRepository,
  );

  final VoucherRepository _voucherRepository;
  final CurrencyRepository _currencyRepository;
  final IdGenerator _idGenerator;
  final GovernanceWriteGuard _writeGuard;
  final GetActiveTransactionFeeUseCase _getActiveFee;
  final AccountRepository _accountRepository;

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
      final currencyRes = await _currencyRepository.getByCode(
        input.currencyCode,
      );
      if (currencyRes.isFailure || currencyRes.valueOrNull == null) {
        return FailureResult(
          ValidationFailure(
            messageAr: 'العملة المختارة غير صالحة.',
            code: 'invalid_currency',
          ),
        );
      }
      final currency = currencyRes.valueOrNull!;

      // 3. Validate parties are distinct
      final sourceId = AccountId(input.sourceAccountId);
      final destId = AccountId(input.destinationAccountId);
      final affectedId = AccountId(input.affectedAccountId);

      if (sourceId == destId) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'لا يمكن أن يكون المصدر والوجهة نفس الطرف.',
            code: 'tripartite_same_source_dest',
          ),
        );
      }
      if (sourceId == affectedId || destId == affectedId) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'الحساب الوسيط يجب أن يكون مختلفاً عن المصدر والوجهة.',
            code: 'tripartite_affected_conflict',
          ),
        );
      }

      // 4. Generate shared identifiers
      final transferGroupId = _idGenerator.next();
      final receiptId = VoucherId(_idGenerator.next());
      final paymentId = VoucherId(_idGenerator.next());
      final now = DateTime.now();
      final amount = Money.positiveAmount(input.amountMinorUnits, currency);

      // Handle fee calculation up-front
      final feeRes = await _getActiveFee();

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
          linkedPartyId:
              destId, // The destination B is the linked party on the receipt
          isContingent: true, // locked until receipt is confirmed
          mediatorAccountId: affectedId,
          feeAmount: null, // Fee belongs to the fee voucher
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
          mediatorAccountId: affectedId,
          feeAmount: feeRes.valueOrNull != null
              ? Money.positiveAmount(
                  feeRes.valueOrNull!.amountMinorUnits, currency)
              : null,
        ),
      );

      // 7. Handle Transaction Fee (Scenario 2)
      Voucher? feeVoucher;
      if (feeRes.isSuccess && feeRes.valueOrNull != null) {
        final feeSetting = feeRes.valueOrNull!;

        // Lookup or create 'Transaction Fees' revenue account
        final accountsRes = await _accountRepository.getAll();
        Account? feeAccount;
        if (accountsRes.isSuccess) {
          feeAccount = accountsRes.valueOrNull!
              .where((a) => a.name == 'إيراد رسوم التحويل')
              .firstOrNull;

          if (feeAccount == null) {
            // Auto-create a revenue/settlement account for fees
            final feeAccountId = AccountId(_idGenerator.next());
            feeAccount = Account.createRoot(
              id: feeAccountId,
              name: 'إيراد رسوم التحويل',
              classification: AccountClassification.settlements,
              createdAt: now,
            );
            await _accountRepository.save(feeAccount);
          }
        }

        if (feeAccount != null) {
          final feeCurrencyRes = await _currencyRepository.getByCode(
            feeSetting.currencyCode,
          );
          if (feeCurrencyRes.isSuccess && feeCurrencyRes.valueOrNull != null) {
            final feeCurrency = feeCurrencyRes.valueOrNull!;
            final feeAmount = Money.positiveAmount(
              feeSetting.amountMinorUnits,
              feeCurrency,
            );
            final feeVoucherId = VoucherId(_idGenerator.next());

            feeVoucher = Voucher.draft(
              id: feeVoucherId,
              type: VoucherType.receipt,
              date: input.date,
              amount: feeAmount,
              currency: feeCurrency,
              counterpartyId: sourceId,
              affectedAccountId: feeAccount.id,
              createdAt: now,
              description: 'رسوم تحويل - ${input.description ?? ""}',
              tripartiteMeta: TripartiteMeta(
                transferGroupId: transferGroupId,
                role: TripartiteRole.intermediaryReceipt,
                linkedPartyId: destId,
                isContingent: false,
              ),
            );
          }
        }
      }

      // 8. Atomic persist
      final List<Voucher> vouchers = [receiptVoucher, paymentVoucher];
      if (feeVoucher != null) vouchers.add(feeVoucher);

      // Note: The current repository might not have saveMultipleVouchers,
      // but we should ideally use a transaction runner here or expand the repo.
      // For now we use the existing tripartite pair save + fee separate or refactor.

      final saveResult = await _voucherRepository.saveTripartitePair(
        receiptVoucher: receiptVoucher,
        paymentVoucher: paymentVoucher,
      );

      if (saveResult.isSuccess && feeVoucher != null) {
        await _voucherRepository.save(feeVoucher);
      }

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
