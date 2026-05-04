import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_output.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/utils/money_formatter.dart';
import 'package:qayd/core/utils/currency_util.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

/// Maps domain DTOs to `{{placeholder}}` keys for [PlaceholderResolver].
abstract final class TemplateBindingMaps {
  static Map<String, String> forVoucher(GetVoucherDetailsOutput d) {
    final date = DateFormat.yMMMd('ar').format(DateTime.parse(d.dateIso));
    final typeAr =
        d.typeCode == 'receipt' ? AppStrings.catchStr : AppStrings.exchange;

    // ── Smart party labels ────────────────────────────────────────────────
    // For standard (non-transfer) vouchers:
    //   counterpartyName = always the external party (receivables/payables)
    //   affectedName     = always the cashbox (liquid assets)
    // The "customer" should ALWAYS be the external party, never the cashbox.
    String senderParty;
    String receiverParty;

    if (d.typeCode == 'receipt') {
      // Receipt: money flows FROM counterparty TO cashbox
      senderParty = d.counterpartyName;
      receiverParty = d.affectedName;
    } else {
      // Payment: money flows FROM cashbox TO counterparty
      senderParty = d.affectedName;
      receiverParty = d.counterpartyName;
    }
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
    if (d.senderSignatureHex != null) sigParts.add(AppStrings.sender);
    if (d.receiverSignatureHex != null) sigParts.add(AppStrings.recipient);

    String signatureLabel;
    if (sigParts.isEmpty) {
      signatureLabel = AppStrings.includedWithDigitalDocumentation;
    } else {
      final names = sigParts.join(AppStrings.and);
      signatureLabel = 'تم التوقيع بواسطة: $names';

      // If only one signature, we can append a truncated hex for quick reference
      if (sigParts.length == 1) {
        final hex = d.senderSignatureHex ?? d.receiverSignatureHex;
        if (hex != null) {
          signatureLabel += ' (${hex.substring(0, 8)})';
        }
      }
    }

    return {
      'customer':
          d.counterpartyName, // Always the external party, never the cashbox
      'counterparty': d.counterpartyName,
      'sender_party': senderParty,
      'receiver_party': receiverParty,
      'amount': MoneyFormatter.formatWithSymbol(
        d.amountMinorUnits /
            (d.currencyDigits == 0 ? 1 : (d.currencyDigits == 2 ? 100 : 1000)),
        CurrencyUtil.getLocalizedName(d.currencyCode),
        fractionalDigits: d.currencyDigits,
      ),
      'currency': CurrencyUtil.getLocalizedName(d.currencyCode),

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
      'net_balance': d.counterpartyBalances.entries.map((e) {
        final digits = (e.key == d.currencyCode) ? d.currencyDigits : 2;
        final divisor = digits == 0 ? 1 : (digits == 2 ? 100 : 1000);
        final value = e.value / divisor;
        final absValue = value.abs();
        final label = d.counterpartyNature == 'debit'
            ? value > 0
                ? AppStrings.onYou
                : AppStrings.your
            : value < 0
                ? AppStrings.onYou
                : AppStrings.your;
        return '${MoneyFormatter.formatDecimal(absValue, minimumFractionDigits: digits, maximumFractionDigits: digits)} ${CurrencyUtil.getLocalizedName(e.key)} $label'
            .trim();
      }).join(', '),
    };
  }

  static String _buildSignatureVerificationString(GetVoucherDetailsOutput d) {
    final hasSender = d.senderSignatureHex != null;
    final hasReceiver = d.receiverSignatureHex != null;

    if (!hasSender && !hasReceiver) {
      return AppStrings.automaticallyExportedAndDigitally;
    }

    final buffer = StringBuffer(AppStrings.blockchainVerification);

    if (hasSender) {
      final label = (d.transferGroupId != null || d.isTripartite) &&
              d.typeCode == 'receipt'
          ? AppStrings.signatureOfTheSending
          : AppStrings.signatureOfTheBond;
      buffer.write('\n- $label: ${d.senderSignatureHex}');
    }

    if (hasReceiver) {
      final label = (d.transferGroupId != null || d.isTripartite) &&
              d.typeCode == 'payment'
          ? AppStrings.signatureOfTheReceiving
          : AppStrings.signatureOfTheOpposite;
      buffer.write('\n- $label: ${d.receiverSignatureHex}');
    }

    buffer.write(AppStrings.nTheAuthenticityOf);
    return buffer.toString();
  }

  static Map<String, String> forAccount(GetAccountDetailsOutput d) {
    final balanceStr = d.balancesMinorUnits.entries
        .map((e) =>
            '${MoneyFormatter.formatDecimal(e.value.abs() / 100)} ${CurrencyUtil.getLocalizedName(e.key)}')
        .join(', ');
    final nature =
        d.natureCode == 'debit' ? AppStrings.creditor : AppStrings.debtor;
    return {
      'account_name': d.name,
      'balance': balanceStr,
      'account_id': d.accountId,
      'nature': nature,
    };
  }
}
