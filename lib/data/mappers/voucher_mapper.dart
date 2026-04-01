import 'dart:convert';

import 'package:qayd/data/models/voucher_model.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/attachment_ref.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/signature_status.dart';
import 'package:qayd/domain/value_objects/tripartite_meta.dart';
import 'package:qayd/domain/value_objects/tripartite_role.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

final class VoucherMapper {
  static VoucherModel toModel(Voucher voucher) {
    final tags = jsonEncode(voucher.tags);
    final attachments = jsonEncode(
      voucher.attachmentRefs
          .map(
            (a) => {
              'path': a.storagePath,
              if (a.mimeType != null) 'mimeType': a.mimeType,
              if (a.byteSize != null) 'byteSize': a.byteSize,
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
      signatureHex: voucher.signatureHex,
      signerPublicKeyHex: voucher.signerPublicKeyHex,
      signatureStatus: voucher.signatureStatus.name,
      signerPhone: voucher.signerPhone,
      transferGroupId: voucher.tripartiteMeta?.transferGroupId,
      tripartiteRole: voucher.tripartiteMeta?.role.columnValue,
      linkedPartyId: voucher.tripartiteMeta?.linkedPartyId.value,
      isContingent: voucher.tripartiteMeta?.isContingent ?? false,
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
        storagePath: m['path'] as String,
        mimeType: m['mimeType'] as String?,
        byteSize: m['byteSize'] as int?,
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
      signatureHex: model.signatureHex,
      signerPublicKeyHex: model.signerPublicKeyHex,
      signatureStatus: _parseSignatureStatus(model.signatureStatus),
      signerPhone: model.signerPhone,
      tripartiteMeta: _parseTripartiteMeta(model),
    );
  }

  static SignatureStatus _parseSignatureStatus(String raw) {
    for (final s in SignatureStatus.values) {
      if (s.name == raw) return s;
    }
    return SignatureStatus.unsigned;
  }

  /// Reconstructs [TripartiteMeta] from model fields; returns null if absent.
  static TripartiteMeta? _parseTripartiteMeta(VoucherModel model) {
    if (model.transferGroupId == null || model.tripartiteRole == null) {
      return null;
    }
    final role = TripartiteRole.fromColumnValue(model.tripartiteRole);
    if (role == null) return null;
    return TripartiteMeta(
      transferGroupId: model.transferGroupId!,
      role: role,
      linkedPartyId: AccountId(model.linkedPartyId ?? ''),
      isContingent: model.isContingent,
    );
  }
}
