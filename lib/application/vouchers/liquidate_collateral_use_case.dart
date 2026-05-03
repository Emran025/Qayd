import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/application/vouchers/dtos/liquidation_result.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/collateral_repository.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/services/balance_calculator.dart';
import 'package:qayd/domain/services/entry_generator.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/collateral_id.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


/// Liquidates a collateral by generating automated settlement accounting entries.
///
/// Implements the spec's §4.2 "Automated Settlement Entries":
///   - **Voucher Settlement:** Covers only the linked voucher amount
///   - **Full Debt Settlement:** Covers the counterparty's total outstanding balance
///   - **Surplus Handling:** Auto-creates a linked receipt voucher for any surplus
///
/// Accounting entries generated:
///   1. Dr. Cash/Bank (sale proceeds)   |  Cr. Counterparty (debt cleared)
///   2. If surplus: auto-generated Receipt Voucher
///      Dr. Cash surplus → Cr. "Held for Customer" liability
class LiquidateCollateralUseCase {
  LiquidateCollateralUseCase({
    required this.collateralRepository,
    required this.voucherRepository,
    required this.ledgerRepository,
    required this.accountRepository,
    required this.entryGenerator,
    required this.balanceCalculator,
    required this.idGenerator,
    required this.governanceWriteGuard,
  });

  final CollateralRepository collateralRepository;
  final VoucherRepository voucherRepository;
  final LedgerRepository ledgerRepository;
  final AccountRepository accountRepository;
  final EntryGenerator entryGenerator;
  final BalanceCalculator balanceCalculator;
  final IdGenerator idGenerator;
  final GovernanceWriteGuard governanceWriteGuard;

  /// [settlementType]: 'voucher' for single voucher, 'full_debt' for total balance
  /// [saleValueMinor]: The actual sale/liquidation value of the collateral
  Future<Result<LiquidationResult>> call({
    required CollateralId collateralId,
    required String settlementType,
    required int saleValueMinor,
  }) async {
    try {
      // Gate check
      final gate = await governanceWriteGuard.assertWritesPermitted();
      if (gate.isFailure) return FailureResult(gate.failureOrNull!);

      // 1. Load collateral
      final collateralResult = await collateralRepository.getById(collateralId);
      if (collateralResult.isFailure) {
        return FailureResult(collateralResult.failureOrNull!);
      }
      final collateral = collateralResult.valueOrNull!;

      if (collateral.isTerminal) {
        return FailureResult(ValidationFailure(
          messageAr: AppStringsAr.thisMortgageCannotBe,
          code: 'collateral_already_terminal',
        ));
      }

      // 2. Load the linked voucher
      final voucherResult =
          await voucherRepository.getById(collateral.voucherId);
      if (voucherResult.isFailure) {
        return FailureResult(voucherResult.failureOrNull!);
      }
      final linkedVoucher = voucherResult.valueOrNull!;

      // 3. Determine debt amount
      int debtMinor;
      if (settlementType == 'full_debt') {
        // Calculate total outstanding balance for the counterparty
        final entriesResult = await ledgerRepository.getEntriesForAccount(
          linkedVoucher.counterpartyId,
        );
        if (entriesResult.isFailure) {
          return FailureResult(entriesResult.failureOrNull!);
        }
        final entries = entriesResult.valueOrNull ?? [];
        // Use debit nature for counterparty (receivable) balance calculation
        final balance = balanceCalculator.signedBalanceMinorUnits(
          entries: entries,
          accountId: linkedVoucher.counterpartyId,
          nature: AccountNature.debit,
        );
        debtMinor = balance.abs();
      } else {
        // Voucher settlement: debt = only the linked voucher amount
        debtMinor = linkedVoucher.amount.minorUnits;
      }

      if (debtMinor <= 0) {
        return FailureResult(ValidationFailure(
          messageAr: AppStringsAr.thereIsNoDebt,
          code: 'no_outstanding_debt',
        ));
      }

      // 4. Create the settlement voucher (Receipt: sale proceeds)
      final settledAmount =
          saleValueMinor >= debtMinor ? debtMinor : saleValueMinor;
      final settlementVoucherId = VoucherId(idGenerator.next());

      final settlementVoucher = Voucher.draft(
        id: settlementVoucherId,
        type: VoucherType.receipt,
        date: DateTime.now(),
        amount: Money.positiveAmount(settledAmount, linkedVoucher.currency),
        currency: linkedVoucher.currency,
        counterpartyId: linkedVoucher.counterpartyId,
        affectedAccountId: linkedVoucher.affectedAccountId,
        createdAt: DateTime.now(),
        description: 'تسوية رهن - تصفية ضمان "${collateral.description}"',
      );

      await voucherRepository.save(settlementVoucher);

      // 5. Handle surplus
      String? surplusReceiptId;
      final surplusMinor = saleValueMinor - debtMinor;

      if (surplusMinor > 0) {
        surplusReceiptId = idGenerator.next();
        final surplusVoucher = Voucher.draft(
          id: VoucherId(surplusReceiptId),
          type: VoucherType.receipt,
          date: DateTime.now(),
          amount: Money.positiveAmount(surplusMinor, linkedVoucher.currency),
          currency: linkedVoucher.currency,
          counterpartyId: linkedVoucher.counterpartyId,
          affectedAccountId: linkedVoucher.affectedAccountId,
          createdAt: DateTime.now(),
          description: AppStringsAr.mortgageLiquidationSurplusHeld,
        );
        await voucherRepository.save(surplusVoucher);
      }

      // 6. Mark collateral as liquidated
      final liquidated = collateral.markLiquidated();
      await collateralRepository.update(liquidated);

      return Success(LiquidationResult(
        settlementVoucherId: settlementVoucherId.value,
        settledAmountMinor: settledAmount,
        surplusAmountMinor: surplusMinor > 0 ? surplusMinor : 0,
        surplusReceiptVoucherId: surplusReceiptId,
      ));
    } catch (e) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
