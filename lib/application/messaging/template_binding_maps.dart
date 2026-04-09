import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_output.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/utils/money_formatter.dart';

/// Maps domain DTOs to `{{placeholder}}` keys for [PlaceholderResolver].
abstract final class TemplateBindingMaps {
  static Map<String, String> forVoucher(GetVoucherDetailsOutput d) {
    final date = DateFormat.yMMMd('ar').format(DateTime.parse(d.dateIso));
    final typeAr = d.typeCode == 'receipt' ? 'قبض' : 'صرف';
    return {
      'customer': d.counterpartyName,
      'counterparty': d.counterpartyName,
      'amount': MoneyFormatter.formatWithSymbol(
        d.amountMinorUnits / (d.currencyDigits == 0 ? 1 : (d.currencyDigits == 2 ? 100 : 100)),
        d.currencySymbol,
        fractionalDigits: d.currencyDigits,
      ),
      'currency': d.currencyCode,
      'date': date,
      'affected_account': d.affectedName,
      'reference': d.referenceNumber ?? '',
      'description': d.description ?? '',
      'notes': d.notes ?? '',
      'voucher_id': d.id,
      'type': typeAr,
      'account_id': d.affectedAccountId,
      'affected_account_id': d.affectedAccountId,
      'counterparty_id': d.counterpartyAccountId,
      'signature': d.senderSignatureHex ?? d.receiverSignatureHex ?? 'مشمول بالتوقيع الإلكتروني',
      'signature_verification': d.senderSignatureHex != null || d.receiverSignatureHex != null 
          ? 'تم التحقق رقمياً: ${d.senderSignatureHex ?? d.receiverSignatureHex}' 
          : 'مُصدّر آلياً وموثق رقمياً عبر نظام قيد',
    };
  }

  static Map<String, String> forAccount(GetAccountDetailsOutput d) {
    final balanceStr = d.balancesMinorUnits.entries
        .map((e) => '${MoneyFormatter.formatDecimal(e.value.abs() / 100)} ${e.key}')
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
