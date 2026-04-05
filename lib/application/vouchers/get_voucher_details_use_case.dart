import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_input.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/attachment_repository.dart';
import 'package:qayd/domain/repositories/collateral_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/services/voucher_qr_service.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/data/security/license_vault.dart';

class GetVoucherDetailsUseCase {
  GetVoucherDetailsUseCase(
    this._voucherRepository,
    this._accountRepository,
    this._qrService,
    this._licenseVault,
    this._attachmentRepository,
    this._collateralRepository,
  );

  final VoucherRepository _voucherRepository;
  final AccountRepository _accountRepository;
  final VoucherQrService _qrService;
  final LicenseVault _licenseVault;
  final AttachmentRepository _attachmentRepository;
  final CollateralRepository _collateralRepository;

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
      final ownerPhone = (licenseData['user']?['phone'] ?? licenseData['phone']) as String?;

      String? linkedPartyName;
      if (v.tripartiteMeta?.linkedPartyId != null) {
        linkedPartyName = await nameFor(v.tripartiteMeta!.linkedPartyId);
      }

      // ── Attachment count ────────────────────────────────────────────────
      int attachmentCount = 0;
      final attachR = await _attachmentRepository.getByVoucherId(v.id);
      if (attachR.isSuccess) {
        attachmentCount = attachR.valueOrNull!.length;
      }

      // ── Collateral info ─────────────────────────────────────────────────
      bool hasCollateral = false;
      String? collateralDescription;
      String? collateralStatusCode;
      int? collateralValueMinor;
      String? collateralExpiryIso;

      final collR = await _collateralRepository.getByVoucherId(v.id);
      if (collR.isSuccess && collR.valueOrNull != null) {
        final coll = collR.valueOrNull!;
        hasCollateral = true;
        collateralDescription = coll.description;
        collateralStatusCode = coll.status.name;
        collateralValueMinor = coll.estimatedValue.minorUnits;
        collateralExpiryIso = coll.expiryDate?.toIso8601String();
      }

      // ── Successor lookup (Threading v1.3) ────────────────────────────────
      String? successorVoucherId;
      final successorR = await _voucherRepository.getByOriginVoucherId(v.id);
      if (successorR.isSuccess && successorR.valueOrNull!.isNotEmpty) {
        // The first child (earliest) is typically the immediate correction/reversal.
        successorVoucherId = successorR.valueOrNull!.first.id.value;
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
          signatureHex: v.signatureHex,
          signerPublicKeyHex: v.signerPublicKeyHex,
          agreementStatusCode: v.agreementStatus.name,
          originVoucherId: v.originVoucherId?.value,
          attachmentCount: attachmentCount,
          hasCollateral: hasCollateral,
          collateralDescription: collateralDescription,
          collateralStatusCode: collateralStatusCode,
          collateralValueMinor: collateralValueMinor,
          collateralExpiryIso: collateralExpiryIso,
          successorVoucherId: successorVoucherId,
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
