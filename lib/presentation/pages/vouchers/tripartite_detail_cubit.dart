import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/vouchers/dtos/get_tripartite_detail_output.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_input.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/application/vouchers/get_voucher_details_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


// ── States ──────────────────────────────────────────────────────────────────

sealed class TripartiteDetailState {
  const TripartiteDetailState();
}

final class TripartiteDetailInitial extends TripartiteDetailState {
  const TripartiteDetailInitial();
}

final class TripartiteDetailLoading extends TripartiteDetailState {
  const TripartiteDetailLoading();
}

final class TripartiteDetailReady extends TripartiteDetailState {
  const TripartiteDetailReady(this.data);

  final GetTripartiteDetailOutput data;
}

final class TripartiteDetailFailure extends TripartiteDetailState {
  const TripartiteDetailFailure(this.failure);

  final Failure failure;
}

// ── Cubit ───────────────────────────────────────────────────────────────────

/// Loads both legs of a tripartite transfer and aggregates them into
/// a single [GetTripartiteDetailOutput] for the detail page.
class TripartiteDetailCubit extends Cubit<TripartiteDetailState> {
  TripartiteDetailCubit(this._getDetails)
      : super(const TripartiteDetailInitial());

  final GetVoucherDetailsUseCase _getDetails;

  /// Loads the tripartite transfer detail from both voucher IDs.
  ///
  /// At minimum, one of [receiptVoucherId] or [paymentVoucherId] must be
  /// provided. Both will be used if available.
  Future<void> load({
    String? receiptVoucherId,
    String? paymentVoucherId,
    required String transferGroupId,
    required String sourceName,
    required String destinationName,
    required String mediatorName,
    required int amountMinorUnits,
    required String currencyCode,
    required String currencySymbol,
    required int currencyDigits,
    required String currencyNameAr,
    required String dateIso,
  }) async {
    emit(const TripartiteDetailLoading());

    try {
      GetVoucherDetailsOutput? receiptData;
      GetVoucherDetailsOutput? paymentData;

      if (receiptVoucherId != null) {
        final r = await _getDetails(
          GetVoucherDetailsInput(voucherId: receiptVoucherId),
        );
        if (r.isSuccess) receiptData = r.valueOrNull;
      }

      if (paymentVoucherId != null) {
        final r = await _getDetails(
          GetVoucherDetailsInput(voucherId: paymentVoucherId),
        );
        if (r.isSuccess) paymentData = r.valueOrNull;
      }

      if (receiptData == null && paymentData == null) {
        emit( TripartiteDetailFailure(
          UnexpectedFailure(messageAr: AppStrings.noBondDataFound),
        ));
        return;
      }

      // Derive signature info from both legs.
      // Receipt leg: sender is A (source), so senderSignature = A's signature.
      // Payment leg: sender is C (mediator), receiver is B (destination).
      // For the tripartite receipt we want: A's signature + B's signature.
      final senderSig = receiptData?.senderSignatureHex;
      final receiverSig = paymentData?.receiverSignatureHex;
      final senderPub = receiptData?.senderPublicKeyHex;
      final receiverPub = paymentData?.receiverPublicKeyHex;
      final senderStatus = receiptData?.senderStatusCode ?? 'underRequest';
      final receiverStatus = paymentData?.receiverStatusCode ?? 'underRequest';

      final firstData = receiptData ?? paymentData!;

      emit(TripartiteDetailReady(GetTripartiteDetailOutput(
        transferGroupId: transferGroupId,
        sourceName: sourceName,
        destinationName: destinationName,
        mediatorName: mediatorName,
        amountMinorUnits: amountMinorUnits,
        currencyCode: currencyCode,
        currencySymbol: currencySymbol,
        currencyDigits: currencyDigits,
        currencyNameAr: currencyNameAr,
        dateIso: dateIso,
        description: firstData.description,
        receiptVoucher: receiptData,
        paymentVoucher: paymentData,
        senderSignatureHex: senderSig,
        receiverSignatureHex: receiverSig,
        senderPublicKeyHex: senderPub,
        receiverPublicKeyHex: receiverPub,
        senderStatusCode: senderStatus,
        receiverStatusCode: receiverStatus,
        sourceAccountId: receiptData?.counterpartyAccountId,
        destinationAccountId: paymentData?.counterpartyAccountId,
        mediatorAccountId: firstData.affectedAccountId,
        qrData: firstData.qrData,
        createdAtIso: firstData.createdAtIso,
      )));
    } catch (e) {
      emit( TripartiteDetailFailure(
        UnexpectedFailure(messageAr: AppStrings.errorLoadingTripleConversion),
      ));
    }
  }
}
