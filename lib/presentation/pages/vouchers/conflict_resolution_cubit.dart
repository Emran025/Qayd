import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_input.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/application/vouchers/get_voucher_details_use_case.dart';
import 'package:qayd/application/vouchers/resolve_conflict_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/notification_message.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


sealed class ConflictResolutionState {
  const ConflictResolutionState();
}

final class ConflictResolutionInitial extends ConflictResolutionState {}

final class ConflictResolutionLoading extends ConflictResolutionState {}

final class ConflictResolutionReady extends ConflictResolutionState {
  const ConflictResolutionReady({
    required this.notification,
    required this.localVoucher,
    required this.inboundPayload,
    this.isResolving = false,
  });

  final NotificationMessage notification;
  final GetVoucherDetailsOutput localVoucher;
  final Map<String, dynamic> inboundPayload;
  final bool isResolving;

  ConflictResolutionReady copyWith({bool? isResolving}) {
    return ConflictResolutionReady(
      notification: notification,
      localVoucher: localVoucher,
      inboundPayload: inboundPayload,
      isResolving: isResolving ?? this.isResolving,
    );
  }
}

final class ConflictResolutionSuccess extends ConflictResolutionState {}

final class ConflictResolutionFailure extends ConflictResolutionState {
  const ConflictResolutionFailure(this.failure);
  final Failure failure;
}

class ConflictResolutionCubit extends Cubit<ConflictResolutionState> {
  ConflictResolutionCubit(
    this._getDetails,
    this._resolve,
  ) : super(ConflictResolutionInitial());

  final GetVoucherDetailsUseCase _getDetails;
  final ResolveConflictUseCase _resolve;

  Future<void> load(NotificationMessage notification) async {
    emit(ConflictResolutionLoading());
    try {
      if (notification.rawPayloadJson == null) {
        emit( ConflictResolutionFailure(
          ValidationFailure(messageAr: AppStrings.missingBondInformationIn),
        ));
        return;
      }

      final data =
          jsonDecode(notification.rawPayloadJson!) as Map<String, dynamic>;
      final localId = data['local_voucher_id'] as String;
      final inboundPayload = data['inbound_payload'] as Map<String, dynamic>;

      final res = await _getDetails(GetVoucherDetailsInput(voucherId: localId));

      res.fold(
        (f) => emit(ConflictResolutionFailure(f)),
        (out) => emit(ConflictResolutionReady(
          notification: notification,
          localVoucher: out,
          inboundPayload: inboundPayload,
        )),
      );
    } catch (_) {
      emit( ConflictResolutionFailure(
        DatabaseFailure(messageAr: AppStrings.unableToLoadComparison),
      ));
    }
  }

  Future<void> resolve({required bool merge}) async {
    final s = state;
    if (s is! ConflictResolutionReady || s.isResolving) return;

    emit(s.copyWith(isResolving: true));

    final res = await _resolve(
      notificationId: s.notification.id,
      localVoucherId: s.localVoucher.id,
      merge: merge,
    );

    res.fold(
      (f) => emit(ConflictResolutionFailure(f)),
      (_) => emit(ConflictResolutionSuccess()),
    );
  }
}
