/// SQLite projection for [vouchers] (v37 schema — is_inbound flag).
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
    this.signerPhone,
    this.canonicalSenderPhone,
    this.canonicalReceiverPhone,
    this.transferGroupId,
    this.tripartiteRole,
    this.linkedPartyId,
    this.mediatorAccountId,
    this.feeAmountMinor,
    required this.isContingent,
    this.originVoucherId,
    this.rejectionReason,
    this.withdrawnAtIso,
    this.reversalCount = 0,
    this.firstChildId,
    required this.senderStatus,
    required this.receiverStatus,
    this.isInbound = false,
    this.senderSignatureHex,
    this.receiverSignatureHex,
    this.senderPublicKeyHex,
    this.receiverPublicKeyHex,
    required this.lifecycleStatus,
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
  final String? signerPhone;

  // Canonical Signature Phones (Protocol v2.1)
  final String? canonicalSenderPhone;
  final String? canonicalReceiverPhone;

  // Tripartite transfer fields
  final String? transferGroupId;
  final String? tripartiteRole;
  final String? linkedPartyId;
  final String? mediatorAccountId;
  final int? feeAmountMinor;
  final bool isContingent;

  // Threaded Financial Interactions fields (Protocol v1.3)
  final String? originVoucherId;
  final String? rejectionReason;
  final String? withdrawnAtIso;
  final int reversalCount;
  final String? firstChildId;

  // Inbound-sync flag (Migration 037)
  /// True when this voucher was received from the counterparty via sync,
  /// not created locally.
  final bool isInbound;

  // Dual signatures and lifecycle (Protocol v2.0)
  final String senderStatus;
  final String receiverStatus;
  final String? senderSignatureHex;
  final String? receiverSignatureHex;
  final String? senderPublicKeyHex;
  final String? receiverPublicKeyHex;
  final String lifecycleStatus;

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
        'signer_phone': signerPhone,
        'canonical_sender_phone': canonicalSenderPhone,
        'canonical_receiver_phone': canonicalReceiverPhone,
        'transfer_group_id': transferGroupId,
        'tripartite_role': tripartiteRole,
        'linked_party_id': linkedPartyId,
        'mediator_account_id': mediatorAccountId,
        'fee_amount_minor': feeAmountMinor,
        'is_contingent': isContingent ? 1 : 0,
        'origin_voucher_id': originVoucherId,
        'rejection_reason': rejectionReason,
        'withdrawn_at': withdrawnAtIso,
        'sender_status': senderStatus,
        'receiver_status': receiverStatus,
        'sender_signature_hex': senderSignatureHex,
        'receiver_signature_hex': receiverSignatureHex,
        'sender_public_key_hex': senderPublicKeyHex,
        'receiver_public_key_hex': receiverPublicKeyHex,
        'lifecycle_status': lifecycleStatus,
        'is_inbound': isInbound ? 1 : 0,
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
      signerPhone: map['signer_phone'] as String?,
      canonicalSenderPhone: map['canonical_sender_phone'] as String?,
      canonicalReceiverPhone: map['canonical_receiver_phone'] as String?,
      transferGroupId: map['transfer_group_id'] as String?,
      tripartiteRole: map['tripartite_role'] as String?,
      linkedPartyId: map['linked_party_id'] as String?,
      mediatorAccountId: map['mediator_account_id'] as String?,
      feeAmountMinor: map['fee_amount_minor'] as int?,
      isContingent: (map['is_contingent'] as int?) == 1,
      originVoucherId: map['origin_voucher_id'] as String?,
      rejectionReason: map['rejection_reason'] as String?,
      withdrawnAtIso: map['withdrawn_at'] as String?,
      reversalCount: (map['reversal_count'] as int?) ?? 0,
      firstChildId: map['first_child_id'] as String?,
      senderStatus: (map['sender_status'] as String?) ?? 'accepted',
      receiverStatus: (map['receiver_status'] as String?) ?? 'under_request',
      isInbound: (map['is_inbound'] as int?) == 1,
      senderSignatureHex: map['sender_signature_hex'] as String?,
      receiverSignatureHex: map['receiver_signature_hex'] as String?,
      senderPublicKeyHex: map['sender_public_key_hex'] as String?,
      receiverPublicKeyHex: map['receiver_public_key_hex'] as String?,
      lifecycleStatus: (map['lifecycle_status'] as String?) ?? 'draft',
    );
  }
}
