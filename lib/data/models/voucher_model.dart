/// SQLite projection for [vouchers] (v6 schema — includes currency_code).
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
    );
  }
}
