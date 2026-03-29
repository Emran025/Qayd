import 'dart:convert';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

class VoucherQrService {
  const VoucherQrService();

  /// Serializes a voucher into a compact base64-encoded JSON string for QR display.
  String generateQrData(Voucher voucher) {
    final map = {
      'v': 1,
      't': voucher.type == VoucherType.payment ? 'P' : 'R',
      'a': voucher.amount.minorUnits,
      'c': voucher.currency.code,
      'd': voucher.date.toIso8601String().split('T')[0],
      'm': voucher.description,
      'r': voucher.referenceNumber,
    };
    final jsonStr = json.encode(map);
    return base64.encode(utf8.encode(jsonStr));
  }

  /// Parses a QR string into a map of suggested fields for a new voucher.
  Map<String, dynamic>? parseQrData(String data) {
    try {
      final decoded = utf8.decode(base64.decode(data));
      final map = json.decode(decoded) as Map<String, dynamic>;
      
      if (map['v'] != 1) return null;

      // Reverse role: If they made a Payment, I made a Receipt
      final sourceType = map['t'] == 'P' ? VoucherType.payment : VoucherType.receipt;
      final targetType = sourceType == VoucherType.payment 
          ? VoucherType.receipt 
          : VoucherType.payment;

      return {
        'type': targetType,
        'amountMinorUnits': map['a'] as int,
        'currencyCode': map['c'] as String,
        'date': DateTime.parse(map['d'] as String),
        'description': map['m'] as String?,
        'referenceNumber': map['r'] as String?,
      };
    } catch (_) {
      return null;
    }
  }
}
