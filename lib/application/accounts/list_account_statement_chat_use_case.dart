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
  }) async {
    try {
      final myId = AccountId(myAccountId);
      final cpId = AccountId(counterpartyAccountId);

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

      // Validate accounts exist (better UX than empty chat).
      final myAccR = await accountRepository.getById(myId);
      if (myAccR.isFailure) return FailureResult(myAccR.failureOrNull!);
      final cpAccR = await accountRepository.getById(cpId);
      if (cpAccR.isFailure) return FailureResult(cpAccR.failureOrNull!);

      final allVouchers = <Voucher>[...aR.valueOrNull!, ...bR.valueOrNull!];
      allVouchers.sort((a, b) {
        final c = a.date.compareTo(b.date);
        if (c != 0) return c;
        return a.createdAt.compareTo(b.createdAt);
      });

      // ── Apply view-mode filtering and calculate brought-forward ──
      // "My Accounts" (Default): Perspective of the user (everything they claim + everything accepted).
      // "Other Party Accounts": Perspective of the counterparty (everything they claim + what the user accepted).
      
      bool isIncludedInView(Voucher v, String direction) {
        if (v.agreementStatus == AgreementStatus.rejected) return false;
        if (filter.viewMode == StatementChatViewMode.myAccounts) return true;
        
        // In "Other Party Accounts" mode:
        // Include if Accepted (mutual or acknowledged).
        if (v.agreementStatus == AgreementStatus.accepted) return true;
        
        // Include if "Their Claim" (they uploaded it and it's pending).
        // A payment they sent to me is 'incoming' and 'underRequest'.
        if (v.agreementStatus == AgreementStatus.underRequest && direction == 'incoming') {
          return true;
        }

        // Exclude if "My Claim" that they haven't approved yet.
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
            final dir = _directionFromMyPerspective(
              vType: v.type,
              affected: v.affectedAccountId,
              counterparty: v.counterpartyId,
              myId: myId,
            );
            if (isIncludedInView(v, dir)) {
              if (dir == 'incoming') {
                broughtForward += v.amount.minorUnits;
              } else {
                broughtForward -= v.amount.minorUnits;
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
        );
        periodVouchers =
            periodVouchers.where((v) => !v.date.isAfter(toEnd)).toList();
      }

      // ── Apply filters ──
      var filtered = periodVouchers;

      // View Mode filtering
      filtered = filtered.where((v) {
        final dir = _directionFromMyPerspective(
          vType: v.type,
          affected: v.affectedAccountId,
          counterparty: v.counterpartyId,
          myId: myId,
        );
        return isIncludedInView(v, dir);
      }).toList();

      // Agreement status filter
      if (filter.agreementStatus != null) {
        filtered = filtered
            .where((v) => v.agreementStatus == filter.agreementStatus)
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
        final direction = _directionFromMyPerspective(
          vType: v.type,
          affected: v.affectedAccountId,
          counterparty: v.counterpartyId,
          myId: myId,
        );

        // All vouchers currently in 'filtered' list are already verified by isIncludedInView.
        if (direction == 'incoming') {
          runningBalance += v.amount.minorUnits;
        } else {
          runningBalance -= v.amount.minorUnits;
        }

        final mergedDescription = (v.description ?? v.notes ?? '').trim();

        messages.add(AccountStatementChatMessageDto(
          voucherId: v.id.value,
          dateIso: v.date.toIso8601String(),
          direction: direction,
          typeCode: v.type.name,
          voucherStateCode: v.state.name,
          signatureStatusCode: v.agreementStatus.name,
          amountMinorUnits: v.amount.minorUnits,
          currencyCode: v.currency.code,
          currencySymbol: v.currency.symbol,
          currencyDigits: v.currency.fractionalDigits,
          description: mergedDescription,
          runningBalanceMinorUnits: runningBalance,
          referenceNumber: v.referenceNumber,
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

  String _directionFromMyPerspective({
    required VoucherType vType,
    required AccountId affected,
    required AccountId counterparty,
    required AccountId myId,
  }) {
    final isMyAffected = affected == myId;

    // Receipt: money in to affected from counterparty.
    if (vType == VoucherType.receipt) {
      return isMyAffected ? 'incoming' : 'outgoing';
    }

    // Payment: money out from affected to counterparty.
    if (vType == VoucherType.payment) {
      return isMyAffected ? 'outgoing' : 'incoming';
    }

    return isMyAffected ? 'incoming' : 'incoming';
  }
}
