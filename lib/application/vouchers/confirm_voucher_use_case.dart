import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/application/vouchers/dtos/confirm_voucher_input.dart';
import 'package:qayd/application/vouchers/dtos/confirm_voucher_output.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/services/entry_generator.dart';
import 'package:qayd/domain/value_objects/entry_id.dart';
import 'package:qayd/domain/value_objects/entry_side.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';

class ConfirmVoucherUseCase {
  ConfirmVoucherUseCase(
    this._voucherRepository,
    this._entryGenerator,
    this._idGenerator,
    this._writeGuard,
  );

  final VoucherRepository _voucherRepository;
  final EntryGenerator _entryGenerator;
  final IdGenerator _idGenerator;
  final GovernanceWriteGuard _writeGuard;

  Future<Result<ConfirmVoucherOutput>> call(ConfirmVoucherInput input) async {
    try {
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }
      final loaded = await _voucherRepository.getById(VoucherId(input.voucherId));
      if (loaded.isFailure) {
        return FailureResult(loaded.failureOrNull!);
      }
      final draft = loaded.valueOrNull!;
      final now = DateTime.now();
      final confirmed = draft.confirm(now);

      final transactionId = TransactionId(_idGenerator.next());
      final debitEntryId = EntryId(_idGenerator.next());
      final creditEntryId = EntryId(_idGenerator.next());

      final entries = _entryGenerator.generateForConfirmedVoucher(
        voucher: confirmed,
        transactionId: transactionId,
        debitEntryId: debitEntryId,
        creditEntryId: creditEntryId,
        ledgerCreatedAt: now,
      );

      final debitLine = entries.firstWhere((e) => e.side == EntrySide.debit);
      final creditLine = entries.firstWhere((e) => e.side == EntrySide.credit);

      final persisted = await _voucherRepository.saveWithLedgerEntries(
        voucher: confirmed,
        ledgerEntries: entries,
      );
      return persisted.fold(
        (f) => FailureResult(f),
        (_) => Success(
          ConfirmVoucherOutput(
            voucherId: confirmed.id.value,
            transactionId: transactionId.value,
            debitEntryId: debitLine.id.value,
            creditEntryId: creditLine.id.value,
            stateCode: VoucherState.confirmed.name,
          ),
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
