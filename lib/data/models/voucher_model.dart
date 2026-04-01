/// SQLite projection for [vouchers] (v10 schema — includes tripartite transfer fields).
final class VoucherModel {
  const VoucherModel({
    required this.id,
    required this.type,
    this.referenceNumber,
    required this.dateIso,
    required this.amountMinor,
    required this.currencyCode,
    required this.counterpartyId,
    required this.affectedAccountId,
    required this.state,
    this.description,
    this.notes,
    required this.tagsJson,
    required this.attachmentsJson,
    required this.createdAtIso,
    this.confirmedAtIso,
    this.settledAtIso,
    this.signatureHex,
    this.signerPublicKeyHex,
    required this.signatureStatus,
    this.signerPhone,
    this.transferGroupId,
    this.tripartiteRole,
    this.linkedPartyId,
    required this.isContingent,
  });

  final String id;
  final String type;
  final String? referenceNumber;
  final String dateIso;
  final int amountMinor;
  final String currencyCode;
  final String counterpartyId;
  final String affectedAccountId;
  final String state;
  final String? description;
  final String? notes;
  final String tagsJson;
  final String attachmentsJson;
  final String createdAtIso;
  final String? confirmedAtIso;
  final String? settledAtIso;
  final String? signatureHex;
  final String? signerPublicKeyHex;
  final String signatureStatus;
  final String? signerPhone;

  // Tripartite transfer fields
  final String? transferGroupId;
  final String? tripartiteRole;
  final String? linkedPartyId;
  final bool isContingent;

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type,
        'reference_number': referenceNumber,
        'date': dateIso,
        'amount_minor': amountMinor,
        'currency_code': currencyCode,
        'counterparty_id': counterpartyId,
        'affected_account_id': affectedAccountId,
        'state': state,
        'description': description,
        'notes': notes,
        'tags_json': tagsJson,
        'attachments_json': attachmentsJson,
        'created_at': createdAtIso,
        'confirmed_at': confirmedAtIso,
        'settled_at': settledAtIso,
        'signature_hex': signatureHex,
        'signer_public_key_hex': signerPublicKeyHex,
        'signature_status': signatureStatus,
        'signer_phone': signerPhone,
        'transfer_group_id': transferGroupId,
        'tripartite_role': tripartiteRole,
        'linked_party_id': linkedPartyId,
        'is_contingent': isContingent ? 1 : 0,
      };

  factory VoucherModel.fromMap(Map<String, Object?> map) {
    return VoucherModel(
      id: map['id']! as String,
      type: map['type']! as String,
      referenceNumber: map['reference_number'] as String?,
      dateIso: map['date']! as String,
      amountMinor: map['amount_minor']! as int,
      currencyCode: map['currency_code']! as String,
      counterpartyId: map['counterparty_id']! as String,
      affectedAccountId: map['affected_account_id']! as String,
      state: map['state']! as String,
      description: map['description'] as String?,
      notes: map['notes'] as String?,
      tagsJson: map['tags_json']! as String,
      attachmentsJson: map['attachments_json']! as String,
      createdAtIso: map['created_at']! as String,
      confirmedAtIso: map['confirmed_at'] as String?,
      settledAtIso: map['settled_at'] as String?,
      signatureHex: map['signature_hex'] as String?,
      signerPublicKeyHex: map['signer_public_key_hex'] as String?,
      signatureStatus: (map['signature_status'] as String?) ?? 'unsigned',
      signerPhone: map['signer_phone'] as String?,
      transferGroupId: map['transfer_group_id'] as String?,
      tripartiteRole: map['tripartite_role'] as String?,
      linkedPartyId: map['linked_party_id'] as String?,
      isContingent: (map['is_contingent'] as int?) == 1,
    );
  }
}
