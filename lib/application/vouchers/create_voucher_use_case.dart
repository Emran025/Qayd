import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/application/vouchers/dtos/create_voucher_output.dart';
import 'package:qayd/domain/repositories/attachment_repository.dart';
import 'package:qayd/data/services/attachment_storage_service.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/tripartite_meta.dart';
import 'package:qayd/domain/value_objects/tripartite_role.dart';
import 'package:qayd/domain/value_objects/attachment_ref.dart';
import 'package:qayd/domain/services/receipt_signing_service.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/signable_receipt.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/application/sync/sync_event_dispatcher.dart';
import 'package:qayd/domain/services/entry_generator.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/entry_id.dart';

class CreateVoucherUseCase {
  final VoucherRepository _voucherRepository;
  final CurrencyRepository _currencyRepository;
  final AttachmentRepository _attachmentRepository;
  final AttachmentStorageService _attachmentStorage;
  final IdGenerator _idGenerator;
  final GovernanceWriteGuard _writeGuard;
  final AccountRepository? _accountRepository;
  final ReceiptSigningService? _signingService;
  final Future<CryptoKeyPair?> Function()? _getKeyPair;
  final LicenseVault? _licenseVault;
  final SyncEventDispatcher? _syncEventDispatcher;
  final CostCenterRepository? _costCenterRepository;
  final EntryGenerator? _entryGenerator;

  CreateVoucherUseCase(
    this._voucherRepository,
    this._currencyRepository,
    this._attachmentRepository,
    this._attachmentStorage,
    this._idGenerator,
    this._writeGuard, {
    AccountRepository? accountRepository,
    ReceiptSigningService? signingService,
    Future<CryptoKeyPair?> Function()? getKeyPair,
    LicenseVault? licenseVault,
    SyncEventDispatcher? syncEventDispatcher,
    CostCenterRepository? costCenterRepository,
    EntryGenerator? entryGenerator,
  })  : _accountRepository = accountRepository,
        _signingService = signingService,
        _getKeyPair = getKeyPair,
        _licenseVault = licenseVault,
        _syncEventDispatcher = syncEventDispatcher,
        _costCenterRepository = costCenterRepository,
        _entryGenerator = entryGenerator;

  Future<Result<CreateVoucherOutput>> call(CreateVoucherInput input) async {
    try {
      final voucherId = VoucherId(_idGenerator.next());
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }
      final currencyRes = await _currencyRepository.getByCode(input.currencyCode);
      if (currencyRes.isFailure || currencyRes.valueOrNull == null) {
        return FailureResult(ValidationFailure(
          messageAr: 'العملة المختارة غير صالحة.',
          code: 'invalid_currency',
        ));
      }
      final currency = currencyRes.valueOrNull!;
      final amount = Money.positiveAmount(input.amountMinorUnits, currency);
      TripartiteMeta? tripartiteMeta;
      if (input.transferGroupId != null &&
          input.tripartiteRole != null &&
          input.linkedPartyId != null) {
        tripartiteMeta = TripartiteMeta(
          transferGroupId: input.transferGroupId!,
          role: TripartiteRole.values.firstWhere(
            (r) => r.name == input.tripartiteRole,
            orElse: () => TripartiteRole.intermediaryReceipt,
          ),
          linkedPartyId: AccountId(input.linkedPartyId!),
          isContingent: input.isContingent,
        );
      }

      // ── Process Attachments ───────────────────────────────────────────
      final List<AttachmentRef> attachmentRefs = [];
      if (input.attachments.isNotEmpty) {
        final stored = await Future.wait(
          input.attachments.map((a) => _attachmentStorage.store(a, voucherId)),
        );
        await _attachmentRepository.saveAll(stored);
        
        // Populate refs for the JSON column in vouchers table
        attachmentRefs.addAll(stored.map((s) => AttachmentRef(
          id: s.id,
          storagePath: s.storagePath,
          mimeType: s.mimeType,
          byteSize: s.byteSize,
          encryptedBlobHash: s.encryptedBlobHash,
          sourceType: s.sourceType,
        )));
      }

      var voucher = Voucher.draft(
        id: voucherId,
        type: input.type,
        date: input.date,
        amount: amount,
        currency: currency,
        counterpartyId: AccountId(input.counterpartyAccountId),
        affectedAccountId: AccountId(input.affectedAccountId),
        createdAt: DateTime.now(),
        referenceNumber: input.referenceNumber,
        description: input.description,
        notes: input.notes,
        tripartiteMeta: tripartiteMeta,
        attachmentRefs: attachmentRefs,
        originVoucherId: input.originVoucherId != null 
            ? VoucherId(input.originVoucherId!) 
            : null,
      );

      // ── Handle Immediate User Confirmation (Signing) ──────────────────────
      if (input.confirm) {
        // Sign as sender. 
        if (_signingService != null && _getKeyPair != null) {
            final keyPair = await _getKeyPair?.call();
          if (keyPair != null) {
            final licenseData = await _licenseVault?.readLicenseData();
            final myPhone = licenseData?['phone'] as String? ?? '';
            
            // Re-resolve counterparty phone for canonical signature.
            String cpPhone = '';
            if (_accountRepository != null) {
              final cpParty = await _accountRepository!.getPartyDetails(
                AccountId(input.counterpartyAccountId),
              );
              cpPhone = cpParty.valueOrNull?.phoneNumber ?? '';
            }

            final signable = SignableReceipt(
              amountMinor: input.amountMinorUnits,
              currencyCode: input.currencyCode,
              senderPhone: myPhone,          // We are sending the document
              receiverPhone: cpPhone,
              dateIso: input.date.toIso8601String().split('T').first,
              receiptUuid: voucherId.value,
            );

            final signature = _signingService!.signReceipt(signable, keyPair);
            voucher = voucher.attachSignature(
              signatureHex: signature.signatureHex,
              publicKeyHex: signature.signerPublicKeyHex,
              isSender: true,
              status: AgreementStatus.accepted,
              signerPhone: myPhone,
            );
          }
        }
        
        // Finalize creator validation state to 'confirmed'.
        voucher = voucher.confirm(DateTime.now());
      }

      // ── Protocol §6: Corrective Resubmission / Succession ─────────────────
      if (input.originVoucherId != null) {
        final originRes = await _voucherRepository.getById(
          VoucherId(input.originVoucherId!),
        );
        if (originRes.isSuccess) {
          final origin = originRes.valueOrNull!;
          // If the original was draft or rejected, mark it as withdrawn to
          // effectively "soft delete" it from main views/balances.
          if (origin.state.isDraft ||
              origin.receiverStatus == AgreementStatus.rejected) {
            final superceded = origin.withdraw(DateTime.now());
            await _voucherRepository.save(superceded);
          }
        }
      }

      // ── Accounting Integration: Persistence ──────────────────────────
      final Result<void> saved;
      if (input.confirm && _entryGenerator != null) {
        final now = DateTime.now();
        final transactionId = TransactionId(_idGenerator.next());
        final debitId = EntryId(_idGenerator.next());
        final creditId = EntryId(_idGenerator.next());

        final entries = _entryGenerator!.generateForConfirmedVoucher(
          voucher: voucher,
          transactionId: transactionId,
          debitEntryId: debitId,
          creditEntryId: creditId,
          ledgerCreatedAt: now,
        );

        saved = await _voucherRepository.saveWithLedgerEntries(
          voucher: voucher,
          ledgerEntries: entries,
        );
      } else {
        saved = await _voucherRepository.save(voucher);
      }
      
      // ── Process Cost Center Attachments ───────────────────────────────
      if (saved.isSuccess && input.costCenterTags.isNotEmpty && _costCenterRepository != null) {
        for (final tag in input.costCenterTags) {
          await _costCenterRepository!.attachVoucher(
            voucherId: voucher.id.value,
            costCenterId: tag.costCenterId,
            dimensionIds: tag.dimensionIds,
          );
        }
      }
      
      // §5.A: Enqueue claim into local outbox ONLY if confirmed.
      // We do NOT await this to ensure a "silent" background sync and better UX.
      if (saved.isSuccess && input.confirm && _syncEventDispatcher != null) {
        _syncEventDispatcher!.dispatchVoucherClaim(voucher).ignore();
      }

      return saved.fold(
        (f) => FailureResult(f),
        (_) => Success(
          CreateVoucherOutput(
            voucherId: voucher.id.value,
            stateCode: voucher.state.name,
          ),
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
