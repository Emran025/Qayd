import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/application/vouchers/dtos/confirm_voucher_input.dart';
import 'package:qayd/application/vouchers/dtos/confirm_voucher_output.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/voucher.dart';
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
      final loaded =
          await _voucherRepository.getById(VoucherId(input.voucherId));
      if (loaded.isFailure) {
        return FailureResult(loaded.failureOrNull!);
      }
      final draft = loaded.valueOrNull!;
      
      // 2. Enforce agreement (digital signature) before confirmation.
      // Payers (Payments) sign themselves => usually Accepted by default.
      // Receivers (Receipts) need counterparty signature => must be Accepted.
      if (!draft.agreementStatus.isAccepted) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'لا يمكن تأكيد السند حتى يتم توقيعه من قبل الطرف المسؤول.',
            code: 'voucher_not_accepted',
          ),
        );
      }

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

      if (persisted.isFailure) {
        return FailureResult(persisted.failureOrNull!);
      }

      // ── Cascading release for tripartite transfers ─────────────────────
      // When confirming the receipt leg (A→C), automatically release
      // the contingent payment leg (C→B) so it can be shared/signed.
      await _cascadeTripartiteRelease(confirmed);

      return Success(
        ConfirmVoucherOutput(
          voucherId: confirmed.id.value,
          transactionId: transactionId.value,
          debitEntryId: debitLine.id.value,
          creditEntryId: creditLine.id.value,
          stateCode: VoucherState.confirmed.name,
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }

  /// When an intermediary receipt is confirmed, find and release its
  /// contingent payment sibling within the same transfer group.
  Future<void> _cascadeTripartiteRelease(Voucher confirmed) async {
    final meta = confirmed.tripartiteMeta;
    if (meta == null) return;
    if (!meta.role.isReceipt) return;

    final groupResult = await _voucherRepository.getByTransferGroupId(
      meta.transferGroupId,
    );
    if (groupResult.isFailure) return;

    final siblings = groupResult.valueOrNull!;
    for (final sibling in siblings) {
      final siblingMeta = sibling.tripartiteMeta;
      if (siblingMeta == null) continue;
      if (!siblingMeta.role.isPayment) continue;
      if (!siblingMeta.isContingent) continue;

      // Release the contingent flag by restoring with updated meta.
      final released = Voucher.restore(
        id: sibling.id,
        type: sibling.type,
        referenceNumber: sibling.referenceNumber,
        date: sibling.date,
        amount: sibling.amount,
        currency: sibling.currency,
        counterpartyId: sibling.counterpartyId,
        affectedAccountId: sibling.affectedAccountId,
        state: sibling.state,
        description: sibling.description,
        attachmentRefs: sibling.attachmentRefs,
        notes: sibling.notes,
        tags: sibling.tags,
        createdAt: sibling.createdAt,
        confirmedAt: sibling.confirmedAt,
        settledAt: sibling.settledAt,
        signatureHex: sibling.signatureHex,
        signerPublicKeyHex: sibling.signerPublicKeyHex,
        agreementStatus: sibling.agreementStatus,
        signerPhone: sibling.signerPhone,
        tripartiteMeta: siblingMeta.release(),
      );
      await _voucherRepository.save(released);
    }
  }
}
