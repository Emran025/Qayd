import 'package:qayd/application/accounts/dtos/account_statement_chat_message_dto.dart';
import 'package:qayd/application/accounts/dtos/statement_chat_filter_input.dart';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_query_filter.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

/// Output bundle for the Statement of Account chat use case.
class StatementChatOutput {
  const StatementChatOutput({
    required this.messages,
    required this.broughtForwardMinorUnits,
    required this.finalBalanceMinorUnits,
  });

  final List<AccountStatementChatMessageDto> messages;

  /// Opening balance calculated from vouchers before [fromDate].
  /// Zero when [includePreviousBalance] is false or no date range is set.
  final int broughtForwardMinorUnits;

  /// Closing balance after all filtered messages.
  final int finalBalanceMinorUnits;
}

final class ListAccountStatementChatUseCase {
  const ListAccountStatementChatUseCase({
    required this.accountRepository,
    required this.voucherRepository,
  });

  final AccountRepository accountRepository;
  final VoucherRepository voucherRepository;

  Future<Result<StatementChatOutput>> call({
    required String myAccountId,
    required String counterpartyAccountId,
    StatementChatFilterInput filter = StatementChatFilterInput.empty,
    bool isUnified = false,
  }) async {
    try {
      final myId = AccountId(myAccountId);
      final cpId = AccountId(counterpartyAccountId);

      final List<Voucher> allVouchers;
      if (isUnified) {
        // Fetch all vouchers involving this account.
        final f = VoucherQueryFilter(involvedAccountId: cpId);
        final r = await voucherRepository.getAll(filter: f);
        if (r.isFailure) return FailureResult(r.failureOrNull!);
        allVouchers = r.valueOrNull!;
      } else {
        // Include vouchers where either side is affected.
        final f1 = VoucherQueryFilter(
          counterpartyId: cpId,
          affectedAccountId: myId,
        );
        final f2 = VoucherQueryFilter(
          counterpartyId: myId,
          affectedAccountId: cpId,
        );

        final aR = await voucherRepository.getAll(filter: f1);
        if (aR.isFailure) return FailureResult(aR.failureOrNull!);
        final bR = await voucherRepository.getAll(filter: f2);
        if (bR.isFailure) return FailureResult(bR.failureOrNull!);
        allVouchers = <Voucher>[...aR.valueOrNull!, ...bR.valueOrNull!];
      }

      allVouchers.sort((a, b) {
        final c = a.date.compareTo(b.date);
        if (c != 0) return c;
        return a.createdAt.compareTo(b.createdAt);
      });

      // Pre-fetch names for all involved accounts to avoid N+1 issues when isUnified
      final Map<String, String> accountNamesLookup = {};
      final involvedAccountIds = allVouchers
          .expand((v) => [
                v.affectedAccountId.value, 
                v.counterpartyId.value,
                if (v.tripartiteMeta?.mediatorAccountId != null)
                  v.tripartiteMeta!.mediatorAccountId!.value,
              ])
          .toSet();
      
      for (final idStr in involvedAccountIds) {
        final accR = await accountRepository.getById(AccountId(idStr));
        if (accR.isSuccess) {
          accountNamesLookup[idStr] = accR.valueOrNull!.name;
        }
      }

      // ── Apply view-mode filtering and calculate brought-forward ──
      // Perspectice of 'myId' or in unified mode, 'cpId' (the Fund).
      final subjectId = isUnified ? cpId : myId;

      bool isIncludedInView(Voucher v) {
        if (v.state.isWithdrawn) return false;

        // Perspective check: Who are we looking for?
        final bool isMyView = filter.viewMode == StatementChatViewMode.myAccounts;
        final targetId = isMyView ? myId : cpId;

        // If the target party is the Sender, check if they accepted (signed).
        if (v.affectedAccountId == targetId) {
          return v.senderStatus == AgreementStatus.accepted;
        }
        
        // If the target party is the Receiver, check if they accepted (signed).
        if (v.counterpartyId == targetId) {
          return v.receiverStatus == AgreementStatus.accepted;
        }

        return false;
      }

      int broughtForward = 0;
      List<Voucher> periodVouchers = allVouchers;

      if (filter.fromDate != null) {
        final fromStart = DateTime(
          filter.fromDate!.year,
          filter.fromDate!.month,
          filter.fromDate!.day,
        );

        if (filter.includePreviousBalance) {
          final priorVouchers =
              allVouchers.where((v) => v.date.isBefore(fromStart)).toList();
          
          broughtForward = 0;
          for (final v in priorVouchers) {
            final dir = _directionFromPerspective(
              vType: v.type,
              affected: v.affectedAccountId,
              counterparty: v.counterpartyId,
              perspectiveId: subjectId,
            );
            if (isIncludedInView(v)) {
              // Only confirmed or pending claims affect balance.
              // Rejected/Withdrawn ones do not.
              final isRejected = v.receiverStatus == AgreementStatus.rejected;
              final isWithdrawn = v.state.isWithdrawn;

              if (!isRejected && !isWithdrawn) {
                if (dir == 'incoming') {
                  broughtForward += v.amount.minorUnits;
                } else {
                  broughtForward -= v.amount.minorUnits;
                }
              }
            }
          }
        }

        periodVouchers =
            allVouchers.where((v) => !v.date.isBefore(fromStart)).toList();
      }

      if (filter.toDate != null) {
        final toEnd = DateTime(
          filter.toDate!.year,
          filter.toDate!.month,
          filter.toDate!.day,
          23,
          59,
          59,
          59,
        );
        periodVouchers =
            periodVouchers.where((v) => !v.date.isAfter(toEnd)).toList();
      }

      // ── Apply filters ──
      var filtered = periodVouchers;

      // View Mode filtering
      filtered = filtered.where((v) {
        return isIncludedInView(v);
      }).toList();

      // Agreement status filter
      if (filter.agreementStatus != null) {
        filtered = filtered
            .where((v) => v.receiverStatus == filter.agreementStatus)
            .toList();
      }

      // Type filter
      if (filter.type != null) {
        filtered = filtered.where((v) => v.type == filter.type).toList();
      }

      // Amount range
      if (filter.amountMinMinorUnits != null) {
        filtered = filtered
            .where((v) => v.amount.minorUnits >= filter.amountMinMinorUnits!)
            .toList();
      }
      if (filter.amountMaxMinorUnits != null) {
        filtered = filtered
            .where((v) => v.amount.minorUnits <= filter.amountMaxMinorUnits!)
            .toList();
      }

      // Text search
      final q = (filter.searchQuery ?? '').trim().toLowerCase();
      if (q.isNotEmpty) {
        filtered = filtered.where((v) {
          final desc = (v.description ?? '').toLowerCase();
          final notes = (v.notes ?? '').toLowerCase();
          final ref = (v.referenceNumber ?? '').toLowerCase();
          final amount = v.amount.minorUnits.toString();
          return desc.contains(q) ||
              notes.contains(q) ||
              ref.contains(q) ||
              amount.contains(q);
        }).toList();
      }

      // ── Build DTOs with running balance ──
      int runningBalance = broughtForward;
      final messages = <AccountStatementChatMessageDto>[];

      for (final v in filtered) {
        final direction = _directionFromPerspective(
          vType: v.type,
          affected: v.affectedAccountId,
          counterparty: v.counterpartyId,
          perspectiveId: subjectId,
        );

        // All vouchers currently in 'filtered' list are already verified by isIncludedInView.
        final isRejected = v.receiverStatus == AgreementStatus.rejected;
        final isWithdrawn = v.state.isWithdrawn;

        if (!isRejected && !isWithdrawn) {
          if (direction == 'incoming') {
            runningBalance += v.amount.minorUnits;
          } else {
            runningBalance -= v.amount.minorUnits;
          }
        }

        final mergedDescription = (v.description ?? v.notes ?? '').trim();

        // Find the "Other" party
        final otherId = v.affectedAccountId == subjectId 
            ? v.counterpartyId.value 
            : v.affectedAccountId.value;
        final otherName = accountNamesLookup[otherId] ?? 'Unknown';

        messages.add(AccountStatementChatMessageDto(
          voucherId: v.id.value,
          dateIso: v.date.toIso8601String(),
          direction: direction,
          typeCode: v.type.name,
          voucherStateCode: v.state.name,
          signatureStatusCode: v.receiverStatus.name,
          amountMinorUnits: v.amount.minorUnits,
          currencyCode: v.currency.code,
          currencySymbol: v.currency.symbol,
          currencyDigits: v.currency.fractionalDigits,
          description: mergedDescription,
          otherPartyId: otherId,
          otherPartyName: otherName,
          runningBalanceMinorUnits: runningBalance,
          referenceNumber: v.referenceNumber,
          mediatorAccountId: v.tripartiteMeta?.mediatorAccountId?.value,
          mediatorName: v.tripartiteMeta?.mediatorAccountId != null 
              ? accountNamesLookup[v.tripartiteMeta!.mediatorAccountId!.value]
              : null,
          feeAmountMinorUnits: v.tripartiteMeta?.feeAmount?.minorUnits,
        ));
      }

      return Success(StatementChatOutput(
        messages: messages,
        broughtForwardMinorUnits: broughtForward,
        finalBalanceMinorUnits: runningBalance,
      ));
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }

  String _directionFromPerspective({
    required VoucherType vType,
    required AccountId affected,
    required AccountId counterparty,
    required AccountId perspectiveId,
  }) {
    final isPerspAffected = affected == perspectiveId;

    // Receipt: money in to affected from counterparty.
    if (vType == VoucherType.receipt) {
      return isPerspAffected ? 'incoming' : 'outgoing';
    }

    // Payment: money out from affected to counterparty.
    if (vType == VoucherType.payment) {
      return isPerspAffected ? 'outgoing' : 'incoming';
    }

    return isPerspAffected ? 'incoming' : 'incoming';
  }
}
