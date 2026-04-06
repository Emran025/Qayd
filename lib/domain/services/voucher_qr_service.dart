import 'dart:convert';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/value_objects/agreement_status.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

class VoucherQrService {
  const VoucherQrService();

  /// Serializes a voucher into a compact base64-encoded JSON string for QR.
  ///
  /// v2 format includes digital signature fields when present.
  /// v3 format includes tripartite transfer metadata fields.
  String generateQrData(Voucher voucher, [String? ownerPhone]) {
    final map = <String, dynamic>{
      // v3 includes tripartite support, v2 includes signature support.
      'v': voucher.tripartiteMeta != null
          ? 3
          : (voucher.hasSignature ? 2 : 1),
      't': voucher.type == VoucherType.payment ? 'P' : 'R',
      'a': voucher.amount.minorUnits,
      'c': voucher.currency.code,
      'd': voucher.date.toIso8601String().split('T')[0],
      'm': voucher.description,
      'r': voucher.referenceNumber,
      'id': voucher.id.value,
      if (ownerPhone != null && ownerPhone.isNotEmpty) 'p': ownerPhone,
      // v2 signature fields (sender/creator's signature).
      if (voucher.senderSignatureHex != null) 'sig': voucher.senderSignatureHex,
      if (voucher.senderPublicKeyHex != null) 'pk': voucher.senderPublicKeyHex,
      if (voucher.signerPhone != null) 'sp': voucher.signerPhone,
      // v3 tripartite fields.
      if (voucher.tripartiteMeta != null) ...{
        'tgid': voucher.tripartiteMeta!.transferGroupId,
        'tgr': voucher.tripartiteMeta!.role.name,
        'tgl': voucher.tripartiteMeta!.linkedPartyId.value,
        'tgc': voucher.tripartiteMeta!.isContingent,
      },
    };
    final jsonStr = json.encode(map);
    return base64.encode(utf8.encode(jsonStr));
  }

  /// Parses a QR string into a map of suggested fields for a new voucher.
  ///
  /// Supports v1 (unsigned), v2 (signed), and v3 (tripartite) formats.
  Map<String, dynamic>? parseQrData(String data) {
    try {
      final decoded = utf8.decode(base64.decode(data));
      final map = json.decode(decoded) as Map<String, dynamic>;

      final version = map['v'] as int? ?? 1;
      if (version < 1 || version > 3) return null;

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
      if (version >= 2) {
        result['signatureHex'] = map['sig'] as String?;
        result['signerPublicKeyHex'] = map['pk'] as String?;
        result['signerPhone'] = map['sp'] as String?;
        result['agreementStatus'] = (map['sig'] != null)
            ? AgreementStatus.accepted.name // matches v.senderStatus re-hydration
            : AgreementStatus.underRequest.name;
      }

      // v3: include tripartite metadata.
      if (version >= 3 && map['tgid'] != null) {
        result['transferGroupId'] = map['tgid'] as String?;
        result['tripartiteRole'] = map['tgr'] as String?;
        result['linkedPartyId'] = map['tgl'] as String?;
        result['isContingent'] = map['tgc'] as bool? ?? false;
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  /// Generates a P2P connection string for WiFi Direct sync.
  /// Format: qayd://p2p?ip=...&port=...&pk=...
  String generateP2PConnectData({
    required String ip,
    required int port,
    required String publicKey,
  }) {
    return 'qayd://p2p?ip=$ip&port=$port&pk=$publicKey';
  }

  /// Checks if the scanned data is a P2P connection link.
  bool isP2PLink(String data) => data.startsWith('qayd://p2p?');

  /// Parses P2P link params into a map.
  Map<String, String>? parseP2PLink(String data) {
    if (!isP2PLink(data)) return null;
    try {
      final uri = Uri.parse(data);
      return {
        'ip': uri.queryParameters['ip'] ?? '',
        'port': uri.queryParameters['port'] ?? '8443',
        'pk': uri.queryParameters['pk'] ?? '',
      };
    } catch (_) {
      return null;
    }
  }
}
