import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_input.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/attachment_repository.dart';
import 'package:qayd/domain/repositories/collateral_repository.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/services/voucher_qr_service.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';

class GetVoucherDetailsUseCase {
  GetVoucherDetailsUseCase(
    this._voucherRepository,
    this._accountRepository,
    this._qrService,
    this._licenseVault,
    this._attachmentRepository,
    this._collateralRepository,
    this._costCenterRepository,
  );

  final VoucherRepository _voucherRepository;
  final AccountRepository _accountRepository;
  final VoucherQrService _qrService;
  final LicenseVault _licenseVault;
  final AttachmentRepository _attachmentRepository;
  final CollateralRepository _collateralRepository;
  final CostCenterRepository _costCenterRepository;

  Future<Result<GetVoucherDetailsOutput>> call(
    GetVoucherDetailsInput input,
  ) async {
    try {
      final vR = await _voucherRepository.getById(VoucherId(input.voucherId));
      if (vR.isFailure) {
        return FailureResult(vR.failureOrNull!);
      }
      final v = vR.valueOrNull!;

      Future<String> nameFor(AccountId id) async {
        final r = await _accountRepository.getById(id);
        if (r.isSuccess) {
          return r.valueOrNull!.name;
        }
        return id.value;
      }

      final counterpartyName = await nameFor(v.counterpartyId);
      final affectedName = await nameFor(v.affectedAccountId);

      final licenseData = await _licenseVault.readLicenseData() ?? {};
      final ownerPhone =
          (licenseData['user']?['phone'] ?? licenseData['phone']) as String?;

      String? linkedPartyName;
      if (v.tripartiteMeta?.linkedPartyId != null) {
        linkedPartyName = await nameFor(v.tripartiteMeta!.linkedPartyId);
      }

      // ── Attachments ─────────────────────────────────────────────────────
      int attachmentCount = 0;
      final List<VoucherAttachmentSummary> attachmentSummaries = [];
      final attachR = await _attachmentRepository.getByVoucherId(v.id);
      if (attachR.isSuccess) {
        final attachments = attachR.valueOrNull!;
        attachmentCount = attachments.length;
        for (final a in attachments) {
          attachmentSummaries.add(VoucherAttachmentSummary(
            id: a.id.value,
            fileName: a.fileName,
            mimeType: a.mimeType,
            byteSize: a.byteSize,
            createdAtIso: a.createdAt.toIso8601String(),
          ));
        }
      }

      // ── Collateral info ─────────────────────────────────────────────────
      bool hasCollateral = false;
      String? collateralDescription;
      String? collateralStatusCode;
      int? collateralValueMinor;
      String? collateralExpiryIso;
      List<String> collateralSettlementVoucherIds = [];

      final collR = await _collateralRepository.getByVoucherId(v.id);
      if (collR.isSuccess && collR.valueOrNull != null) {
        final coll = collR.valueOrNull!;
        hasCollateral = true;
        collateralDescription = coll.description;
        collateralStatusCode = coll.status.name;
        collateralValueMinor = coll.estimatedValue.minorUnits;
        collateralExpiryIso = coll.expiryDate?.toIso8601String();

        // Look up settlement vouchers linked to this voucher
        final settleR = await _voucherRepository.getByOriginVoucherId(v.id);
        if (settleR.isSuccess) {
          collateralSettlementVoucherIds = settleR.valueOrNull!
              .where((sv) =>
                  sv.state == VoucherState.settled ||
                  sv.state == VoucherState.confirmed)
              .map((sv) => sv.id.value)
              .toList();
        }
      }

      // ── Cost / Profit Centers ────────────────────────────────────────────
      final List<CostCenterSummary> costCenters = [];
      final ccIdsR =
          await _costCenterRepository.getCostCenterIdsForVoucher(v.id.value);
      if (ccIdsR.isSuccess) {
        for (final ccId in ccIdsR.valueOrNull!) {
          final ccR = await _costCenterRepository.getById(ccId);
          if (ccR.isSuccess && ccR.valueOrNull != null) {
            final cc = ccR.valueOrNull!;
            costCenters.add(CostCenterSummary(
              id: cc.id,
              name: cc.name,
              typeCode: cc.type.name,
            ));
          }
        }
      }

      // ── Successor lookup (Threading v1.3) ────────────────────────────────
      String? successorVoucherId;
      final successorR = await _voucherRepository.getByOriginVoucherId(v.id);
      if (successorR.isSuccess && successorR.valueOrNull!.isNotEmpty) {
        successorVoucherId = successorR.valueOrNull!.first.id.value;
      }

      // ── Protocol §2: Approval Permissions ────────────────────────────────
      bool canApprove = false;

      final myLicense = await _licenseVault.readLicenseData();
      final myPubKey = (myLicense?['user']?['public_key'] ??
          myLicense?['public_key']) as String?;

      // Ownership check: If we don't have a signature yet, compare account classifications.
      // Internal accounts (Liquid Assets) belong to the local user.
      final affectedRes = await _accountRepository.getById(v.affectedAccountId);
      final isAffectedInternal =
          affectedRes.valueOrNull?.classification.standardKind?.name ==
              'liquidAssets';

      // We are the sender if:
      // 1. Our public key matches the sender signature key.
      // 2. OR There is no signature yet, but the 'affected' account is one of our funds.
      final isMeSender =
          (v.senderPublicKeyHex != null && v.senderPublicKeyHex == myPubKey) ||
              (v.senderPublicKeyHex == null && isAffectedInternal);

      if (!v.isWithdrawn &&
          (v.state == VoucherState.draft ||
              v.state == VoucherState.confirmed)) {
        if (v.receiverStatus == AgreementStatus.underRequest) {
          // Case A: Counterparty Signature (Approval)
          // We can only approve if we are NOT the sender (we didn't create it).
          if (!isMeSender) {
            canApprove = true;
          }
        } else if (v.senderStatus == AgreementStatus.accepted &&
            v.receiverStatus == AgreementStatus.accepted &&
            v.state == VoucherState.draft) {
          // Case B: Final Ledger Confirmation (تأكيد)
          // Both have signed. Now the local user should confirm it into their accounts.
          // This only applies if it's still in 'draft' state.
          canApprove = true;
        }
      }

      return Success(
        GetVoucherDetailsOutput(
          id: v.id.value,
          typeCode: v.type.name,
          stateCode: v.state.name,
          dateIso: v.date.toIso8601String(),
          amountMinorUnits: v.amount.minorUnits,
          currencyCode: v.currency.code,
          currencyNameAr: v.currency.nameAr,
          currencySymbol: v.currency.symbol,
          currencyDigits: v.currency.fractionalDigits,
          counterpartyAccountId: v.counterpartyId.value,
          counterpartyName: counterpartyName,
          affectedAccountId: v.affectedAccountId.value,
          affectedName: affectedName,
          referenceNumber: v.referenceNumber,
          description: v.description,
          notes: v.notes,
          qrData: _qrService.generateQrData(v, ownerPhone),
          createdAtIso: v.createdAt.toIso8601String(),
          confirmedAtIso: v.confirmedAt?.toIso8601String(),
          settledAtIso: v.settledAt?.toIso8601String(),
          isTripartite: v.isTripartite,
          tripartiteRole: v.tripartiteMeta?.role.columnValue,
          linkedPartyId: v.tripartiteMeta?.linkedPartyId.value,
          linkedPartyName: linkedPartyName,
          transferGroupId: v.tripartiteMeta?.transferGroupId,
          isContingent: v.isContingent,
          senderSignatureHex: v.senderSignatureHex,
          receiverSignatureHex: v.receiverSignatureHex,
          senderPublicKeyHex: v.senderPublicKeyHex,
          receiverPublicKeyHex: v.receiverPublicKeyHex,
          senderStatusCode: v.senderStatus.name,
          receiverStatusCode: v.receiverStatus.name,
          canApprove: canApprove,
          originVoucherId: v.originVoucherId?.value,
          attachmentCount: attachmentCount,
          attachments: attachmentSummaries,
          hasCollateral: hasCollateral,
          collateralDescription: collateralDescription,
          collateralStatusCode: collateralStatusCode,
          collateralValueMinor: collateralValueMinor,
          collateralExpiryIso: collateralExpiryIso,
          collateralSettlementVoucherIds: collateralSettlementVoucherIds,
          successorVoucherId: successorVoucherId,
          costCenters: costCenters,
        ),
      );
    } catch (e) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
