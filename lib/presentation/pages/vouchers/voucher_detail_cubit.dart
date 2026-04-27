import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/vouchers/confirm_voucher_use_case.dart';
import 'package:qayd/application/vouchers/withdraw_voucher_use_case.dart';
import 'package:qayd/application/vouchers/dtos/confirm_voucher_input.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_input.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/application/vouchers/get_voucher_details_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/services/attachment_storage_service.dart';
import 'package:qayd/domain/entities/collateral.dart';
import 'package:qayd/domain/entities/collateral_revaluation.dart';
import 'package:qayd/domain/repositories/attachment_repository.dart';
import 'package:qayd/domain/repositories/collateral_repository.dart';
import 'package:qayd/domain/value_objects/collateral_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

sealed class VoucherDetailState {
  const VoucherDetailState();
}

final class VoucherDetailInitial extends VoucherDetailState {
  const VoucherDetailInitial();
}

final class VoucherDetailLoading extends VoucherDetailState {
  const VoucherDetailLoading();
}

final class VoucherDetailReady extends VoucherDetailState {
  const VoucherDetailReady(
    this.data, {
    this.confirming = false,
    this.confirmErrorAr,
    this.showPostConfirmMessage = false,
    this.decryptedAttachments = const [],
    this.attachmentNames = const [],
    this.loadingAttachments = false,
    this.collateralEntity,
    this.collateralRevaluations = const [],
    this.collateralImages = const [],
    this.collateralImageNames = const [],
    this.loadingCollateral = false,
    this.pendingCollateralDialog = false,
  });

  final GetVoucherDetailsOutput data;
  final bool confirming;
  final String? confirmErrorAr;
  final bool showPostConfirmMessage;

  /// Decrypted attachment image bytes for gallery viewing.
  final List<Uint8List> decryptedAttachments;
  final List<String> attachmentNames;
  final bool loadingAttachments;

  /// Full collateral entity and related data.
  final Collateral? collateralEntity;
  final List<CollateralRevaluation> collateralRevaluations;
  final List<Uint8List> collateralImages;
  final List<String> collateralImageNames;
  final bool loadingCollateral;

  /// When true, the UI should open the collateral detail dialog.
  /// Set to true when the user taps the button while data is still loading,
  /// so the dialog opens automatically once loading completes.
  final bool pendingCollateralDialog;
}

final class VoucherDetailFailure extends VoucherDetailState {
  const VoucherDetailFailure(this.failure);

  final Failure failure;
}

class VoucherDetailCubit extends Cubit<VoucherDetailState> {
  VoucherDetailCubit(
    this._getDetails,
    this._confirm,
    this._withdraw, {
    this.attachmentRepository,
    this.attachmentStorage,
    this.collateralRepository,
  }) : super(const VoucherDetailInitial());

  final GetVoucherDetailsUseCase _getDetails;
  final ConfirmVoucherUseCase _confirm;
  final WithdrawVoucherUseCase _withdraw;

  /// Optional: injected only when attachment viewing is needed.
  final AttachmentRepository? attachmentRepository;
  final AttachmentStorageService? attachmentStorage;
  final CollateralRepository? collateralRepository;

  Future<void> load(String voucherId) async {
    emit(const VoucherDetailLoading());
    await _emitDetails(voucherId, showPostConfirmMessage: false);
  }

  Future<void> _emitDetails(
    String voucherId, {
    required bool showPostConfirmMessage,
  }) async {
    final result = await _getDetails(
      GetVoucherDetailsInput(voucherId: voucherId),
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (f) => emit(VoucherDetailFailure(f)),
      (data) {
        emit(
          VoucherDetailReady(
            data,
            showPostConfirmMessage: showPostConfirmMessage,
          ),
        );
        if (data.hasCollateral) {
          loadCollateralDetails();
        }
      },
    );
  }

  /// Decrypts and loads all attachment images for gallery viewing.
  Future<void> loadAttachmentImages() async {
    final s = state;
    if (s is! VoucherDetailReady) return;
    if (s.decryptedAttachments.isNotEmpty || s.loadingAttachments) return;
    if (attachmentRepository == null || attachmentStorage == null) return;

    emit(VoucherDetailReady(
      s.data,
      confirming: s.confirming,
      loadingAttachments: true,
      collateralEntity: s.collateralEntity,
      collateralRevaluations: s.collateralRevaluations,
      collateralImages: s.collateralImages,
      collateralImageNames: s.collateralImageNames,
    ));

    try {
      final voucherId = VoucherId(s.data.id);
      final attachR = await attachmentRepository!.getByVoucherId(voucherId);
      if (isClosed) return;

      if (attachR.isSuccess) {
        final attachments = attachR.valueOrNull!;
        final List<Uint8List> images = [];
        final List<String> names = [];

        for (final att in attachments) {
          if (att.mimeType.startsWith('image/')) {
            try {
              final bytes = await attachmentStorage!.decrypt(att);
              images.add(bytes);
              names.add(att.fileName);
            } catch (_) {
              // Skip corrupted or missing files
            }
          }
        }

        if (isClosed) return;
        final cur = state;
        if (cur is VoucherDetailReady) {
          emit(VoucherDetailReady(
            cur.data,
            confirming: cur.confirming,
            decryptedAttachments: images,
            attachmentNames: names,
            loadingAttachments: false,
            collateralEntity: cur.collateralEntity,
            collateralRevaluations: cur.collateralRevaluations,
            collateralImages: cur.collateralImages,
            collateralImageNames: cur.collateralImageNames,
          ));
        }
      }
    } catch (_) {
      if (isClosed) return;
      final cur = state;
      if (cur is VoucherDetailReady) {
        emit(VoucherDetailReady(
          cur.data,
          confirming: cur.confirming,
          loadingAttachments: false,
          collateralEntity: cur.collateralEntity,
          collateralRevaluations: cur.collateralRevaluations,
          collateralImages: cur.collateralImages,
          collateralImageNames: cur.collateralImageNames,
        ));
      }
    }
  }

  /// Loads full collateral entity, revaluation history, and decrypted images.
  ///
  /// [openDialogWhenReady]: if true, sets [VoucherDetailReady.pendingCollateralDialog]
  /// so the UI can open the detail dialog automatically once loading completes.
  Future<void> loadCollateralDetails({bool openDialogWhenReady = false}) async {
    final s = state;
    if (s is! VoucherDetailReady) return;
    if (collateralRepository == null) return;
    if (!s.data.hasCollateral || s.data.collateralId == null) return;

    // If already loaded, just signal the dialog to open.
    if (s.collateralEntity != null) {
      if (openDialogWhenReady) {
        emit(VoucherDetailReady(
          s.data,
          confirming: s.confirming,
          decryptedAttachments: s.decryptedAttachments,
          attachmentNames: s.attachmentNames,
          collateralEntity: s.collateralEntity,
          collateralRevaluations: s.collateralRevaluations,
          collateralImages: s.collateralImages,
          collateralImageNames: s.collateralImageNames,
          loadingCollateral: false,
          pendingCollateralDialog: true,
        ));
      }
      return;
    }

    // If already loading, just mark that we should open when done.
    if (s.loadingCollateral) {
      if (openDialogWhenReady && !s.pendingCollateralDialog) {
        emit(VoucherDetailReady(
          s.data,
          confirming: s.confirming,
          decryptedAttachments: s.decryptedAttachments,
          attachmentNames: s.attachmentNames,
          loadingCollateral: true,
          pendingCollateralDialog: true,
        ));
      }
      return;
    }

    emit(VoucherDetailReady(
      s.data,
      confirming: s.confirming,
      decryptedAttachments: s.decryptedAttachments,
      attachmentNames: s.attachmentNames,
      loadingCollateral: true,
      pendingCollateralDialog: openDialogWhenReady,
    ));

    try {
      final collId = CollateralId(s.data.collateralId!);
      final collR = await collateralRepository!.getById(collId);
      if (isClosed) return;

      Collateral? coll;
      List<CollateralRevaluation> revals = [];
      List<Uint8List> collImages = [];
      List<String> collImageNames = [];

      if (collR.isSuccess) {
        coll = collR.valueOrNull;
        // Load revaluation history
        final revalR =
            await collateralRepository!.getRevaluationHistory(collId);
        if (revalR.isSuccess) {
          revals = revalR.valueOrNull!;
        }

        // Decrypt collateral images if any
        if (coll != null &&
            coll.imageRefs.isNotEmpty &&
            attachmentStorage != null &&
            attachmentRepository != null) {
          final voucherId = coll.voucherId;
          final attachR = await attachmentRepository!.getByVoucherId(voucherId);
          if (attachR.isSuccess) {
            for (final ref in coll.imageRefs) {
              final match = attachR.valueOrNull!.where(
                (a) => a.id.value == ref.id.value,
              );
              if (match.isNotEmpty) {
                try {
                  final bytes = await attachmentStorage!.decrypt(match.first);
                  collImages.add(bytes);
                  collImageNames.add(match.first.fileName);
                } catch (_) {}
              }
            }
          }
        }
      }

      if (isClosed) return;
      final cur = state;
      if (cur is VoucherDetailReady) {
        emit(VoucherDetailReady(
          cur.data,
          confirming: cur.confirming,
          decryptedAttachments: cur.decryptedAttachments,
          attachmentNames: cur.attachmentNames,
          loadingCollateral: false,
          collateralEntity: coll,
          collateralRevaluations: revals,
          collateralImages: collImages,
          collateralImageNames: collImageNames,
          // Preserve the pending dialog flag so the UI can react.
          pendingCollateralDialog: cur.pendingCollateralDialog,
        ));
      }
    } catch (_) {
      if (isClosed) return;
      final cur = state;
      if (cur is VoucherDetailReady) {
        emit(VoucherDetailReady(
          cur.data,
          confirming: cur.confirming,
          decryptedAttachments: cur.decryptedAttachments,
          attachmentNames: cur.attachmentNames,
          loadingCollateral: false,
        ));
      }
    }
  }

  /// Called by the UI after it has consumed the pendingCollateralDialog signal.
  void clearPendingCollateralDialog() {
    final s = state;
    if (s is VoucherDetailReady && s.pendingCollateralDialog) {
      emit(VoucherDetailReady(
        s.data,
        confirming: s.confirming,
        decryptedAttachments: s.decryptedAttachments,
        attachmentNames: s.attachmentNames,
        collateralEntity: s.collateralEntity,
        collateralRevaluations: s.collateralRevaluations,
        collateralImages: s.collateralImages,
        collateralImageNames: s.collateralImageNames,
        loadingCollateral: s.loadingCollateral,
        pendingCollateralDialog: false,
      ));
    }
  }

  Future<void> confirm() async {
    final s = state;
    if (s is! VoucherDetailReady || s.confirming) {
      return;
    }
    if (s.data.stateCode != 'draft') {
      return;
    }
    emit(
      VoucherDetailReady(
        s.data,
        confirming: true,
        confirmErrorAr: null,
      ),
    );
    final result = await _confirm(
      ConfirmVoucherInput(voucherId: s.data.id),
    );
    if (isClosed) {
      return;
    }
    if (result.isFailure) {
      emit(
        VoucherDetailReady(
          s.data,
          confirming: false,
          confirmErrorAr: result.failureOrNull!.messageAr,
        ),
      );
      return;
    }
    emit(const VoucherDetailLoading());
    await _emitDetails(s.data.id, showPostConfirmMessage: true);
  }

  void clearConfirmError() {
    final s = state;
    if (s is VoucherDetailReady && s.confirmErrorAr != null) {
      emit(VoucherDetailReady(s.data));
    }
  }

  void clearPostConfirmMessage() {
    final s = state;
    if (s is VoucherDetailReady && s.showPostConfirmMessage) {
      emit(VoucherDetailReady(s.data));
    }
  }

  Future<void> withdraw() async {
    final s = state;
    if (s is! VoucherDetailReady || s.confirming) return;

    emit(VoucherDetailReady(s.data, confirming: true));
    final result = await _withdraw(voucherId: s.data.id);

    if (isClosed) return;

    if (result.isFailure) {
      emit(VoucherDetailReady(
        s.data,
        confirming: false,
        confirmErrorAr: result.failureOrNull!.messageAr,
      ));
      return;
    }

    emit(const VoucherDetailLoading());
    await _emitDetails(s.data.id, showPostConfirmMessage: false);
  }
}
