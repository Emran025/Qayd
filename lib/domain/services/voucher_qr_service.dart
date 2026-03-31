import 'dart:convert';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/value_objects/signature_status.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

class VoucherQrService {
  const VoucherQrService();

  /// Serializes a voucher into a compact base64-encoded JSON string for QR.
  ///
  /// v2 format includes digital signature fields when present.
  String generateQrData(Voucher voucher, [String? ownerPhone]) {
    final map = <String, dynamic>{
      // v2 includes signature support.
      'v': voucher.signatureStatus.hasCryptographicSignature ? 2 : 1,
      't': voucher.type == VoucherType.payment ? 'P' : 'R',
      'a': voucher.amount.minorUnits,
      'c': voucher.currency.code,
      'd': voucher.date.toIso8601String().split('T')[0],
      'm': voucher.description,
      'r': voucher.referenceNumber,
      'id': voucher.id.value,
      if (ownerPhone != null && ownerPhone.isNotEmpty) 'p': ownerPhone,
      // v2 signature fields.
      if (voucher.signatureHex != null) 'sig': voucher.signatureHex,
      if (voucher.signerPublicKeyHex != null) 'pk': voucher.signerPublicKeyHex,
      if (voucher.signerPhone != null) 'sp': voucher.signerPhone,
    };
    final jsonStr = json.encode(map);
    return base64.encode(utf8.encode(jsonStr));
  }

  /// Parses a QR string into a map of suggested fields for a new voucher.
  ///
  /// Supports both v1 (unsigned) and v2 (signed) formats.
  Map<String, dynamic>? parseQrData(String data) {
    try {
      final decoded = utf8.decode(base64.decode(data));
      final map = json.decode(decoded) as Map<String, dynamic>;

      final version = map['v'] as int? ?? 1;
      if (version != 1 && version != 2) return null;

      // Reverse role: If they made a Payment, I made a Receipt.
      final sourceType =
          map['t'] == 'P' ? VoucherType.payment : VoucherType.receipt;
      final targetType = sourceType == VoucherType.payment
          ? VoucherType.receipt
          : VoucherType.payment;

      final result = <String, dynamic>{
        'version': version,
        'type': targetType,
        'amountMinorUnits': map['a'] as int,
        'currencyCode': map['c'] as String,
        'date': DateTime.parse(map['d'] as String),
        'description': map['m'] as String?,
        'referenceNumber': map['r'] as String?,
        'counterpartyPhone': map['p'] as String?,
        'receiptUuid': map['id'] as String?,
      };

      // v2: include signed receipt data.
      if (version == 2) {
        result['signatureHex'] = map['sig'] as String?;
        result['signerPublicKeyHex'] = map['pk'] as String?;
        result['signerPhone'] = map['sp'] as String?;
        result['signatureStatus'] = (map['sig'] != null)
            ? SignatureStatus.signed
            : SignatureStatus.unsigned;
      }

      return result;
    } catch (_) {
      return null;
    }
  }
}
