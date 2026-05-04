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
import 'package:qayd/domain/value_objects/entry_id.dart';
import 'package:qayd/domain/value_objects/entry_side.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/services/balance_calculator.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

class GetVoucherDetailsUseCase {
  GetVoucherDetailsUseCase(
    this._voucherRepository,
    this._accountRepository,
    this._qrService,
    this._licenseVault,
    this._attachmentRepository,
    this._collateralRepository,
    this._costCenterRepository,
    this._ledgerRepository,
  );

  final VoucherRepository _voucherRepository;
  final AccountRepository _accountRepository;
  final VoucherQrService _qrService;
  final LicenseVault _licenseVault;
  final AttachmentRepository _attachmentRepository;
  final CollateralRepository _collateralRepository;
  final CostCenterRepository _costCenterRepository;
  final LedgerRepository _ledgerRepository;

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
      final ownerName =
          (licenseData['user']?['name'] ?? licenseData['name']) as String?;

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
      final coll = collR.valueOrNull;
      if (collR.isSuccess && coll != null) {
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
            final List<DimensionSummary> dimensions = [];

            final dimsR = await _costCenterRepository.getDimensionsForVoucher(
              voucherId: v.id.value,
              costCenterId: cc.id,
            );
            if (dimsR.isSuccess) {
              for (final d in dimsR.valueOrNull!) {
                dimensions.add(DimensionSummary(
                  id: d.id,
                  name: d.name,
                  categoryName: d.category.name,
                ));
              }
            }

            costCenters.add(CostCenterSummary(
              id: cc.id,
              name: cc.name,
              typeCode: cc.type.name,
              dimensions: dimensions,
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

      // ── Counterparty Balance calculation ────────────────────────────────
      final Map<String, int> counterpartyBalances = {};
      final cpAccountR = await _accountRepository.getById(v.counterpartyId);
      if (cpAccountR.isSuccess) {
        final cpAccount = cpAccountR.valueOrNull!;
        final entriesR =
            await _ledgerRepository.getEntriesForAccount(v.counterpartyId);
        if (entriesR.isSuccess) {
          final allEntries = entriesR.valueOrNull!;
          // Find entries belonging to this voucher to calculate running balance
          int maxIdx = -1;
          for (int i = 0; i < allEntries.length; i++) {
            if (allEntries[i].voucherId == v.id) {
              maxIdx = i;
            }
          }

          List<LedgerEntry> relevantEntries;
          if (maxIdx != -1) {
            // Include everything up to the last entry of this voucher
            relevantEntries = allEntries.sublist(0, maxIdx + 1);
          } else {
            // Voucher might not be in ledger yet (e.g. draft or pending).
            // We'll calculate balance as "Current Ledger Balance + This Voucher Impact"
            final virtualEntry = LedgerEntry.create(
              id: EntryId('virtual-total'),
              transactionId: TransactionId('virtual-total'),
              accountId: v.counterpartyId,
              side: v.type == VoucherType.receipt
                  ? EntrySide.credit
                  : EntrySide.debit,
              amount: v.amount,
              currency: v.currency,
              voucherId: v.id,
              date: v.date,
              createdAt: v.createdAt,
            );
            relevantEntries = [...allEntries, virtualEntry];
          }

          final balancesMap =
              const BalanceCalculator().signedBalanceMinorUnitsPerCurrency(
            entries: relevantEntries,
            accountId: v.counterpartyId,
            nature: cpAccount.nature,
          );
          for (final entry in balancesMap.entries) {
            counterpartyBalances[entry.key.code] = entry.value;
          }
        }
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

      // The local user is the creator if:
      // - They are the sender (isMeSender is true)
      // - OR there are no signatures yet, meaning it's a local draft.
      // - OR the affected account is an internal account (not a customer/supplier).
      final isInternalAccount =
          affectedRes.valueOrNull?.nature.name != 'customer' &&
              affectedRes.valueOrNull?.nature.name != 'supplier';

      final isCreator = isMeSender ||
          (v.senderPublicKeyHex == null && v.receiverPublicKeyHex == null) ||
          isInternalAccount;

      if (!v.isWithdrawn && v.state == VoucherState.draft) {
        // The creator can always confirm their own draft into the ledger.
        if (isCreator) {
          canApprove = true;
        }
        // The receiver can approve (sign) if it's under request.
        else if (v.receiverStatus == AgreementStatus.underRequest) {
          canApprove = true;
        }
      } else if (!v.isWithdrawn && v.state == VoucherState.confirmed) {
        // If it's already confirmed but we are the receiver and haven't signed, we can still "Approve" (sign).
        if (!isCreator && v.receiverStatus == AgreementStatus.underRequest) {
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
          counterpartyNature: cpAccountR.valueOrNull?.nature.name,
          affectedNature: affectedRes.valueOrNull?.nature.name,
          referenceNumber: v.referenceNumber,
          description: v.description,
          notes: v.notes,
          qrData: _qrService.generateQrData(
            v,
            ownerPhone: ownerPhone,
            ownerName: ownerName,
            collateral: coll,
          ),
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
          collateralId: hasCollateral ? collR.valueOrNull!.id.value : null,
          collateralDescription: collateralDescription,
          collateralStatusCode: collateralStatusCode,
          collateralValueMinor: collateralValueMinor,
          collateralExpiryIso: collateralExpiryIso,
          collateralSettlementVoucherIds: collateralSettlementVoucherIds,
          successorVoucherId: successorVoucherId,
          costCenters: costCenters,
          isCreator: isCreator,
          counterpartyBalances: counterpartyBalances,
        ),
      );
    } catch (e) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
