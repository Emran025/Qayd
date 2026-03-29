import 'package:qayd/application/accounts/dtos/get_account_details_output.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/domain/entities/message_template.dart';

sealed class NotificationPreviewState {
  const NotificationPreviewState();
}

final class NotificationPreviewLoading extends NotificationPreviewState {
  const NotificationPreviewLoading();
}

final class NotificationPreviewReady extends NotificationPreviewState {
  const NotificationPreviewReady({
    required this.templates,
    required this.selectedTemplateId,
    required this.bodyText,
    this.voucher,
    this.account,
  });

  final List<MessageTemplate> templates;
  final String? selectedTemplateId;
  final String bodyText;
  final GetVoucherDetailsOutput? voucher;
  final GetAccountDetailsOutput? account;

  String get entityType => voucher != null ? 'voucher' : 'account';

  String get entityId => voucher?.id ?? account!.accountId;
}

final class NotificationPreviewFailure extends NotificationPreviewState {
  const NotificationPreviewFailure(this.failure);

  final Failure failure;
}
