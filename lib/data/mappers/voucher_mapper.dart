import 'dart:convert';

import 'package:qayd/data/models/voucher_model.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/attachment_id.dart';
import 'package:qayd/domain/value_objects/attachment_ref.dart';
import 'package:qayd/domain/value_objects/attachment_source_type.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/tripartite_meta.dart';
import 'package:qayd/domain/value_objects/tripartite_role.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_lifecycle.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:uuid/uuid.dart';

final class VoucherMapper {
  static VoucherModel toModel(Voucher voucher) {
    final tags = jsonEncode(voucher.tags);
    final attachments = jsonEncode(
      voucher.attachmentRefs
          .map(
            (a) => {
              'id': a.id.value,
              'path': a.storagePath,
              if (a.mimeType != null) 'mimeType': a.mimeType,
              if (a.byteSize != null) 'byteSize': a.byteSize,
              if (a.encryptedBlobHash != null) 'blobHash': a.encryptedBlobHash,
              if (a.thumbnailPath != null) 'thumbPath': a.thumbnailPath,
              'source': a.sourceType.name,
            },
          )
          .toList(),
    );
    return VoucherModel(
      id: voucher.id.value,
      type: voucher.type.name,
      referenceNumber: voucher.referenceNumber,
      dateIso: voucher.date.toIso8601String(),
      amountMinor: voucher.amount.minorUnits,
      currencyCode: voucher.currency.code,
      counterpartyId: voucher.counterpartyId.value,
      affectedAccountId: voucher.affectedAccountId.value,
      state: voucher.state.name,
      description: voucher.description,
      notes: voucher.notes,
      tagsJson: tags,
      attachmentsJson: attachments,
      createdAtIso: voucher.createdAt.toIso8601String(),
      confirmedAtIso: voucher.confirmedAt?.toIso8601String(),
      settledAtIso: voucher.settledAt?.toIso8601String(),
      senderStatus: voucher.senderStatus.name,
      receiverStatus: voucher.receiverStatus.name,
      senderSignatureHex: voucher.senderSignatureHex,
      receiverSignatureHex: voucher.receiverSignatureHex,
      senderPublicKeyHex: voucher.senderPublicKeyHex,
      receiverPublicKeyHex: voucher.receiverPublicKeyHex,
      lifecycleStatus: voucher.lifecycleStatus.name,
      signerPhone: voucher.signerPhone,
      transferGroupId: voucher.tripartiteMeta?.transferGroupId,
      tripartiteRole: voucher.tripartiteMeta?.role.columnValue,
      linkedPartyId: voucher.tripartiteMeta?.linkedPartyId.value,
      mediatorAccountId: voucher.tripartiteMeta?.mediatorAccountId?.value,
      feeAmountMinor: voucher.tripartiteMeta?.feeAmount?.minorUnits,
      isContingent: voucher.tripartiteMeta?.isContingent ?? false,
      originVoucherId: voucher.originVoucherId?.value,
      rejectionReason: voucher.rejectionReason,
      withdrawnAtIso: voucher.withdrawnAt?.toIso8601String(),
    );
  }

  static Voucher toEntity(VoucherModel model, CurrencyCode currency) {
    final tags = (jsonDecode(model.tagsJson) as List<dynamic>)
        .map((e) => e as String)
        .toList();
    final rawAttach = jsonDecode(model.attachmentsJson) as List<dynamic>;
    final refs = rawAttach.map((e) {
      final m = e as Map<String, dynamic>;
      return AttachmentRef(
        id: AttachmentId(m['id'] as String? ?? const Uuid().v4()),
        storagePath: m['path'] as String,
        mimeType: m['mimeType'] as String?,
        byteSize: m['byteSize'] as int?,
        encryptedBlobHash: m['blobHash'] as String?,
        thumbnailPath: m['thumbPath'] as String?,
        sourceType: AttachmentSourceType.fromString(
          m['source'] as String? ?? 'gallery',
        ),
      );
    }).toList();

    return Voucher.restore(
      id: VoucherId(model.id),
      type: VoucherType.values.byName(model.type),
      referenceNumber: model.referenceNumber,
      date: DateTime.parse(model.dateIso),
      amount: Money.positiveAmount(model.amountMinor, currency),
      currency: currency,
      counterpartyId: AccountId(model.counterpartyId),
      affectedAccountId: AccountId(model.affectedAccountId),
      state: VoucherState.values.byName(model.state),
      description: model.description,
      attachmentRefs: refs,
      notes: model.notes,
      tags: tags,
      createdAt: DateTime.parse(model.createdAtIso),
      confirmedAt: model.confirmedAtIso != null
          ? DateTime.parse(model.confirmedAtIso!)
          : null,
      settledAt:
          model.settledAtIso != null ? DateTime.parse(model.settledAtIso!) : null,
      senderStatus: _parseAgreementStatus(model.senderStatus),
      receiverStatus: _parseAgreementStatus(model.receiverStatus),
      senderSignatureHex: model.senderSignatureHex,
      receiverSignatureHex: model.receiverSignatureHex,
      senderPublicKeyHex: model.senderPublicKeyHex,
      receiverPublicKeyHex: model.receiverPublicKeyHex,
      lifecycleStatus: _parseLifecycleStatus(model.lifecycleStatus),
      signerPhone: model.signerPhone,
      tripartiteMeta: _parseTripartiteMeta(model, currency),
      originVoucherId: model.originVoucherId != null
          ? VoucherId(model.originVoucherId!)
          : null,
      rejectionReason: model.rejectionReason,
      withdrawnAt: model.withdrawnAtIso != null
          ? DateTime.parse(model.withdrawnAtIso!)
          : null,
      reversalCount: model.reversalCount,
      firstChildId:
          model.firstChildId != null ? VoucherId(model.firstChildId!) : null,
    );
  }

  static AgreementStatus _parseAgreementStatus(String raw) {
    for (final s in AgreementStatus.values) {
      if (s.name == raw) return s;
    }
    return AgreementStatus.underRequest;
  }

  static VoucherLifecycle _parseLifecycleStatus(String raw) {
    for (final s in VoucherLifecycle.values) {
      if (s.name == raw) return s;
    }
    return VoucherLifecycle.draft;
  }

  /// Reconstructs [TripartiteMeta] from model fields; returns null if absent.
  static TripartiteMeta? _parseTripartiteMeta(VoucherModel model, CurrencyCode currency) {
    if (model.transferGroupId == null || model.tripartiteRole == null) {
      return null;
    }
    final role = TripartiteRole.fromColumnValue(model.tripartiteRole);
    if (role == null) return null;
    return TripartiteMeta(
      transferGroupId: model.transferGroupId!,
      role: role,
      linkedPartyId: AccountId(model.linkedPartyId ?? ''),
      mediatorAccountId: model.mediatorAccountId != null 
          ? AccountId(model.mediatorAccountId!) 
          : null,
      feeAmount: model.feeAmountMinor != null 
          ? Money.positiveAmount(model.feeAmountMinor!, currency)
          : null,
      isContingent: model.isContingent,
    );
  }
}
