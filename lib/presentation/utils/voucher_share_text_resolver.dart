import 'package:qayd/application/messaging/template_binding_maps.dart';
import 'package:qayd/application/vouchers/dtos/get_tripartite_detail_output.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/services/placeholder_resolver.dart';
import 'package:qayd/domain/value_objects/message_template_kind.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';

Future<String?> resolveVoucherShareText(GetVoucherDetailsOutput data) async {
  try {
    final kind = data.typeCode == 'receipt'
        ? MessageTemplateKind.receipt
        : MessageTemplateKind.payment;
    final tR =
        await InjectionContainer.messageTemplateRepository.getByKind(kind);
    if (tR.isFailure) return null;
    final templates = tR.valueOrNull!;
    if (templates.isEmpty) return null;

    // Choose the first / default template
    final template = templates.first;
    final bindings = TemplateBindingMaps.forVoucher(data);
    return PlaceholderResolver.resolve(template.body, bindings);
  } catch (_) {
    return null;
  }
}

Future<String> resolveVoucherShareTextWithFallback(
    GetVoucherDetailsOutput data) async {
  final templateText = await resolveVoucherShareText(data);
  if (templateText != null && templateText.isNotEmpty) {
    return templateText;
  }

  final bindings = TemplateBindingMaps.forVoucher(data);
  final shortId = data.id.length > 8 ? data.id.substring(0, 8) : data.id;
  final reference = data.referenceNumber ?? shortId;

  String body;
  if (data.isTripartite) {
    body =
        'مرفق لكم إشعار تحويل مالي من حساب ${bindings['sender_party']} إلى حساب ${bindings['receiver_party']}.\n'
        'المبلغ: ${bindings['amount']}\n'
        'المرجع: $reference\n';
    AppStrings.nautomaticallyExportedAndDigitally;
  } else {
    final voucherType = data.typeCode == 'receipt'
        ? AppStrings.receiptNotice
        : AppStrings.disbursementNotice;
    body = 'مرفق لكم $voucherType للعميل ${data.counterpartyName}.\n'
        'المبلغ: ${bindings['amount']}\n';

    body += 'الحساب: ${data.affectedName}\n';
    if (data.description != null && data.description!.isNotEmpty) {
      body += 'البيان: ${data.description}\n';
    }

    if (bindings['net_balance']?.isNotEmpty == true) {
      body += 'الرصيد الإجمالي: ${bindings['net_balance']}\n';
    }

    body += 'المرجع: $reference\n';
    AppStrings.nautomaticallyExportedAndDigitally;
  }

  if (data.senderSignatureHex != null || data.receiverSignatureHex != null) {
    body +=
        '\nبصمة التحقق: ${data.senderSignatureHex ?? data.receiverSignatureHex}';
  }

  return body;
}

Future<String?> resolveTripartiteShareText(
    GetTripartiteDetailOutput data) async {
  try {
    final buffer = StringBuffer();

    if (data.receiptVoucher != null) {
      final t = await resolveVoucherShareText(data.receiptVoucher!);
      if (t != null) buffer.writeln(t);
    }

    if (data.paymentVoucher != null) {
      if (buffer.isNotEmpty) {
        buffer.writeln('\n------------------------\n');
      }
      final t = await resolveVoucherShareText(data.paymentVoucher!);
      if (t != null) buffer.writeln(t);
    }

    return buffer.isEmpty ? null : buffer.toString();
  } catch (_) {
    return null;
  }
}
