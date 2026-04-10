import 'package:flutter/foundation.dart';
import 'package:qayd/application/suggestions/suggestion_pattern_extractor.dart';
import 'package:qayd/domain/entities/notification_message.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/core/result/result.dart';

/// Intelligent agent that matches incoming messages to existing vouchers.
/// Available as a background process or triggered on new message arrival.
class AnalyzeForSuggestionsUseCase {
  const AnalyzeForSuggestionsUseCase(
    this._voucherRepository,
    this._notificationRepo,
  );

  final VoucherRepository _voucherRepository;
  final NotificationMessageRepository _notificationRepo;

  /// Analyzes a message and attempts to automatically link it to an existing
  /// unconfirmed voucher if the parameters (amount, date, counterparty) match.
  Future<void> call(NotificationMessage message) async {
    try {
      final extraction = SuggestionPatternExtractor.extract(message.bodyText);

      // We need at least an amount and a signature to auto-match/sign.
      if (extraction.amountMinorUnits == null ||
          extraction.signatureHex == null) {
        return;
      }

      final amount = extraction.amountMinorUnits!;
      final signature = extraction.signatureHex!;
      final publicKey = extraction.publicKeyHex;
      final type = SuggestionPatternExtractor.toVoucherType(extraction.direction);

      // 1. Search for a matching voucher for this counterparty.
      final vouchersR = await _voucherRepository.getByCounterparty(
        AccountId(message.counterpartyAccountId),
      );

      if (vouchersR.isFailure) return;
      final vouchers = vouchersR.valueOrNull ?? [];

      // 2. Filter for potential matches:
      // - Same amount
      // - Same date (if extracted)
      // - Not already signed by receiver
      // - Not settled
      final matches = vouchers.where((v) {
        final sameAmount = v.amount.minorUnits == amount;
        final sameType = type == null || v.type == type;
        final alreadySigned = v.receiverSignatureHex != null;
        final finished = v.state == VoucherState.settled;
        
        // Date matching logic (within same day)
        bool sameDate = true;
        if (extraction.date != null) {
          sameDate = v.date.year == extraction.date!.year &&
              v.date.month == extraction.date!.month &&
              v.date.day == extraction.date!.day;
        }

        return sameAmount && sameType && !alreadySigned && !finished && sameDate;
      }).toList();

      if (matches.isEmpty) {
        debugPrint('No matching voucher found for auto-suggestion [${message.id}]');
        return;
      }

      // 3. Auto-match the best (most recent) candidate.
      matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final candidate = matches.first;

      debugPrint('Auto-matching message [${message.id}] to voucher [${candidate.id.value}]');

      // 4. Update the voucher with the extracted signature.
      // Note: We use AgreementStatus.accepted assuming the message represents 
      // an approval. The VerifyIncomingVoucherUseCase would be better for full verification,
      // but here we are doing a "suggested match".
      final updated = candidate.attachSignature(
        signatureHex: signature,
        publicKeyHex: publicKey ?? '',
        isSender: false, // The counterparty (receiver from our POV) signed it.
        status: AgreementStatus.accepted,
      );

      await _voucherRepository.save(updated);

      // 5. Mark message as processed.
      await _notificationRepo.markProcessed(message.id);
      
      debugPrint('Successfully auto-signed voucher [${candidate.id.value}] via SMS/Suggestion.');
    } catch (e) {
      debugPrint('Error during AnalyzeForSuggestions: $e');
    }
  }
}
