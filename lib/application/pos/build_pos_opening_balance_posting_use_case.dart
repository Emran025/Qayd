import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/pos_accounting_posting.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/services/entry_generator.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/entry_id.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

final class BuildPosOpeningBalancePostingInput {
  const BuildPosOpeningBalancePostingInput({
    required this.sourceId,
    required this.voucherId,
    required this.transactionId,
    required this.debitEntryId,
    required this.creditEntryId,
    required this.inventoryAccountId,
    required this.clearingAccountId,
    required this.amountMinorUnits,
    required this.currency,
    required this.date,
    required this.createdAt,
  });

  final String sourceId;
  final String voucherId;
  final String transactionId;
  final String debitEntryId;
  final String creditEntryId;
  final String inventoryAccountId;
  final String clearingAccountId;
  final int amountMinorUnits;
  final CurrencyCode currency;
  final DateTime date;
  final DateTime createdAt;
}

/// Builds the official Qayd voucher/ledger payload for opening stock.
///
/// Persistence is intentionally delegated to a later transaction coordinator.
/// This use case never writes directly to vouchers or ledger_entries.
final class BuildPosOpeningBalancePostingUseCase {
  const BuildPosOpeningBalancePostingUseCase({
    EntryGenerator entryGenerator = const EntryGenerator(),
  }) : _entryGenerator = entryGenerator;

  final EntryGenerator _entryGenerator;

  Future<Result<PosAccountingPosting>> call(
    BuildPosOpeningBalancePostingInput input,
  ) async {
    try {
      final sourceId = input.sourceId.trim();
      if (sourceId.isEmpty) {
        return FailureResult(
          ValidationFailure(messageAr: AppStrings.posAccountingSourceRequired),
        );
      }
      final inventoryAccountId = input.inventoryAccountId.trim();
      final clearingAccountId = input.clearingAccountId.trim();
      if (inventoryAccountId.isEmpty || clearingAccountId.isEmpty) {
        return FailureResult(
          ValidationFailure(
              messageAr: AppStrings.posAccountingAccountsRequired),
        );
      }
      if (inventoryAccountId == clearingAccountId) {
        return FailureResult(
          ValidationFailure(
              messageAr: AppStrings.posAccountingAccountsDistinct),
        );
      }

      final voucher = Voucher.draft(
        id: VoucherId(input.voucherId),
        type: VoucherType.receipt,
        date: input.date,
        amount: Money.positiveAmount(input.amountMinorUnits, input.currency),
        currency: input.currency,
        counterpartyId: AccountId(clearingAccountId),
        affectedAccountId: AccountId(inventoryAccountId),
        createdAt: input.createdAt,
        referenceNumber: sourceId,
        description: AppStrings.posOpeningBalanceAccountingDescription,
      ).confirm(input.createdAt);

      final entries = _entryGenerator.generateForConfirmedVoucher(
        voucher: voucher,
        transactionId: TransactionId(input.transactionId),
        debitEntryId: EntryId(input.debitEntryId),
        creditEntryId: EntryId(input.creditEntryId),
        ledgerCreatedAt: input.createdAt,
      );
      return Success(
        PosAccountingPosting(
          sourceId: sourceId,
          voucher: voucher,
          entries: List.unmodifiable(entries),
        ),
      );
    } catch (error) {
      return FailureResult(failureFromDomainException(error));
    }
  }
}
