import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_output.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/utils/money_formatter.dart';

/// Maps domain DTOs to `{{placeholder}}` keys for [PlaceholderResolver].
abstract final class TemplateBindingMaps {
  static Map<String, String> forVoucher(GetVoucherDetailsOutput d) {
    final date = DateFormat.yMMMd('ar').format(DateTime.parse(d.dateIso));
    final typeAr = d.typeCode == 'receipt' ? 'قبض' : 'صرف';

    // Tripartite / Dual Transfer "Smart" labels
    String senderParty = d.counterpartyName;
    String receiverParty = d.affectedName;
    String affectedAccountLabel = d.affectedName;

    if (d.transferGroupId != null || d.isTripartite) {
      final isReceiptLeg = d.typeCode == 'receipt';
      senderParty =
          isReceiptLeg ? d.counterpartyName : (d.linkedPartyName ?? '—');
      receiverParty =
          isReceiptLeg ? (d.linkedPartyName ?? '—') : d.counterpartyName;

      // Hide mediator name in affected_account for SMS
      affectedAccountLabel = '';
    }

    final sigParts = <String>[];
    if (d.senderSignatureHex != null) sigParts.add('المرسل');
    if (d.receiverSignatureHex != null) sigParts.add('المستلم');

    String signatureLabel;
    if (sigParts.isEmpty) {
      signatureLabel = 'مشمول بالتوقيع الإلكتروني';
    } else {
      final names = sigParts.join(' و ');
      final hex = d.senderSignatureHex ?? d.receiverSignatureHex;
      final truncatedHex = hex != null ? ' (${hex.substring(0, 8)}...)' : '';
      signatureLabel = 'موقع من $names$truncatedHex';
    }

    return {
      'customer': d.typeCode == 'receipt' ? senderParty : receiverParty,
      'counterparty': d.typeCode == 'receipt' ? senderParty : receiverParty,
      'sender_party': senderParty,
      'receiver_party': receiverParty,
      'amount': MoneyFormatter.formatWithSymbol(
        d.amountMinorUnits /
            (d.currencyDigits == 0 ? 1 : (d.currencyDigits == 2 ? 100 : 100)),
        d.currencySymbol,
        fractionalDigits: d.currencyDigits,
      ),
      'currency': d.currencyCode,
      'date': date,
      'affected_account': affectedAccountLabel,
      'reference': d.referenceNumber ?? '',
      'description': d.description ?? '',
      'notes': d.notes ?? '',
      'voucher_id': d.id,
      'type': typeAr,
      'account_id': d.affectedAccountId,
      'affected_account_id': d.affectedAccountId,
      'counterparty_id': d.counterpartyAccountId,
      'signature': signatureLabel,
      'sender_signature': d.senderSignatureHex ?? '',
      'receiver_signature': d.receiverSignatureHex ?? '',
      'signature_verification': _buildSignatureVerificationString(d),
    };
  }

  static String _buildSignatureVerificationString(GetVoucherDetailsOutput d) {
    if (d.senderSignatureHex == null && d.receiverSignatureHex == null) {
      return 'مُصدّر آلياً وموثق رقمياً عبر نظام قيد';
    }

    final buffer = StringBuffer('تم التحقق رقمياً:');
    if (d.senderSignatureHex != null) {
      buffer.write('\n- توقيع المرسل: ${d.senderSignatureHex}');
    }
    if (d.receiverSignatureHex != null) {
      buffer.write('\n- توقيع المستلم: ${d.receiverSignatureHex}');
    }
    return buffer.toString();
  }

  static Map<String, String> forAccount(GetAccountDetailsOutput d) {
    final balanceStr = d.balancesMinorUnits.entries
        .map((e) =>
            '${MoneyFormatter.formatDecimal(e.value.abs() / 100)} ${e.key}')
        .join(', ');
    final nature = d.natureCode == 'debit' ? 'مدين' : 'دائن';
    return {
      'account_name': d.name,
      'balance': balanceStr,
      'account_id': d.accountId,
      'nature': nature,
    };
  }
}
