import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_input.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_output.dart';
import 'package:qayd/application/accounts/get_account_details_use_case.dart';
import 'package:qayd/application/messaging/log_notification_intent_use_case.dart';
import 'package:qayd/application/messaging/template_binding_maps.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_input.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/application/vouchers/get_voucher_details_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/messaging/messaging_intent_launcher.dart';
import 'package:qayd/domain/entities/message_template.dart';
import 'package:qayd/domain/repositories/message_template_repository.dart';
import 'package:qayd/domain/services/placeholder_resolver.dart';
import 'package:qayd/domain/value_objects/message_template_kind.dart';
import 'package:qayd/presentation/pages/messaging/notification_preview_mode.dart';
import 'package:qayd/presentation/pages/messaging/notification_preview_state.dart';
import 'package:qayd/presentation/utils/voucher_share_text_resolver.dart';

class NotificationPreviewCubit extends Cubit<NotificationPreviewState> {
  NotificationPreviewCubit({
    required this.mode,
    required MessageTemplateRepository templateRepository,
    required GetVoucherDetailsUseCase getVoucherDetails,
    required GetAccountDetailsUseCase getAccountDetails,
    required LogNotificationIntentUseCase logIntent,
  })  : _templateRepository = templateRepository,
        _getVoucherDetails = getVoucherDetails,
        _getAccountDetails = getAccountDetails,
        _logIntent = logIntent,
        super(const NotificationPreviewLoading());

  final NotificationPreviewMode mode;
  final MessageTemplateRepository _templateRepository;
  final GetVoucherDetailsUseCase _getVoucherDetails;
  final GetAccountDetailsUseCase _getAccountDetails;
  final LogNotificationIntentUseCase _logIntent;

  Future<void> load() async {
    emit(const NotificationPreviewLoading());
    switch (mode) {
      case NotificationPreviewVoucher(:final voucherId):
        await _loadVoucher(voucherId);
      case NotificationPreviewAccount(:final accountId):
        await _loadAccount(accountId);
    }
  }

  Future<void> _loadVoucher(String voucherId) async {
    final vR = await _getVoucherDetails(
      GetVoucherDetailsInput(voucherId: voucherId),
    );
    if (vR.isFailure) {
      emit(NotificationPreviewFailure(vR.failureOrNull!));
      return;
    }
    final v = vR.valueOrNull!;
    final kind = v.typeCode == 'receipt'
        ? MessageTemplateKind.receipt
        : MessageTemplateKind.payment;
    final tR = await _templateRepository.getByKind(kind);
    if (tR.isFailure) {
      emit(NotificationPreviewFailure(tR.failureOrNull!));
      return;
    }
    final templates = tR.valueOrNull!;
    final bindings = TemplateBindingMaps.forVoucher(v);

    GetAccountDetailsOutput? counterpartyAccount;
    if (v.counterpartyAccountId.isNotEmpty) {
      final aR = await _getAccountDetails(
        GetAccountDetailsInput(accountId: v.counterpartyAccountId),
      );
      if (aR.isSuccess) {
        counterpartyAccount = aR.valueOrNull;
      }
    }

    await _emitReady(
      templates: templates,
      voucher: v,
      account: counterpartyAccount,
      bindings: bindings,
    );
  }

  Future<void> _loadAccount(String accountId) async {
    final aR = await _getAccountDetails(
      GetAccountDetailsInput(accountId: accountId),
    );
    if (aR.isFailure) {
      emit(NotificationPreviewFailure(aR.failureOrNull!));
      return;
    }
    final a = aR.valueOrNull!;
    final tR = await _templateRepository.getByKind(
      MessageTemplateKind.accountBalance,
    );
    if (tR.isFailure) {
      emit(NotificationPreviewFailure(tR.failureOrNull!));
      return;
    }
    final templates = tR.valueOrNull!;
    final bindings = TemplateBindingMaps.forAccount(a);
    await _emitReady(
      templates: templates,
      account: a,
      voucher: null,
      bindings: bindings,
    );
  }

  Future<void> _emitReady({
    required List<MessageTemplate> templates,
    required GetVoucherDetailsOutput? voucher,
    required GetAccountDetailsOutput? account,
    required Map<String, String> bindings,
  }) async {
    final first = templates.isEmpty ? null : templates.first;
    final selectedId = first?.id;

    String body;
    if (first != null) {
      body = PlaceholderResolver.resolve(first.body, bindings);
    } else if (voucher != null) {
      body = await resolveVoucherShareTextWithFallback(voucher);
    } else if (account != null) {
      body =
          'تحية طيبة، رصيد الحساب ${account.name} حالياً هو: ${bindings['balance']}.\n\nمُصدّر آلياً عبر نظام قيد المالي.';
    } else {
      body = '';
    }

    emit(
      NotificationPreviewReady(
        templates: templates,
        selectedTemplateId: selectedId,
        bodyText: body,
        voucher: voucher,
        account: account,
      ),
    );
  }

  void selectTemplate(String templateId) {
    final s = state;
    if (s is! NotificationPreviewReady) {
      return;
    }
    MessageTemplate? picked;
    for (final e in s.templates) {
      if (e.id == templateId) {
        picked = e;
        break;
      }
    }
    if (picked == null) {
      return;
    }
    final bindings = s.voucher != null
        ? TemplateBindingMaps.forVoucher(s.voucher!)
        : TemplateBindingMaps.forAccount(s.account!);
    final body = PlaceholderResolver.resolve(picked.body, bindings);
    emit(
      NotificationPreviewReady(
        templates: s.templates,
        selectedTemplateId: templateId,
        bodyText: body,
        voucher: s.voucher,
        account: s.account,
      ),
    );
  }

  void setBodyText(String text) {
    final s = state;
    if (s is! NotificationPreviewReady) {
      return;
    }
    emit(
      NotificationPreviewReady(
        templates: s.templates,
        selectedTemplateId: s.selectedTemplateId,
        bodyText: text,
        voucher: s.voucher,
        account: s.account,
      ),
    );
  }

  Future<Result<void>> sendSms() async {
    final s = state;
    if (s is! NotificationPreviewReady) {
      return const Success(null);
    }
    final phoneNumber = s.account?.phoneNumber;
    final ok = await MessagingIntentLauncher.openSmsWithBody(
      s.bodyText,
      phoneNumber: phoneNumber,
    );
    if (!ok) {
      return const FailureResult(
        UnexpectedFailure(messageAr: 'تعذر فتح تطبيق الرسائل.'),
      );
    }
    return _logIntent(
      channel: 'sms',
      templateId: s.selectedTemplateId,
      entityType: s.entityType,
      entityId: s.entityId,
      renderedBody: s.bodyText,
      suggestionCounterpartyAccountId:
          s.voucher?.counterpartyAccountId ?? s.account?.accountId,
    );
  }

  Future<Result<void>> sendWhatsApp(WhatsAppFlavor flavor) async {
    final s = state;
    if (s is! NotificationPreviewReady) {
      return const Success(null);
    }
    final targetNumber = s.account?.whatsappNumber ?? s.account?.phoneNumber;
    final ok = await MessagingIntentLauncher.shareToWhatsApp(
      flavor: flavor,
      message: s.bodyText,
      phoneNumber: targetNumber,
    );
    if (!ok) {
      return const FailureResult(
        UnexpectedFailure(messageAr: 'تعذر فتح واتساب.'),
      );
    }
    return _logIntent(
      channel: 'whatsapp',
      templateId: s.selectedTemplateId,
      entityType: s.entityType,
      entityId: s.entityId,
      renderedBody: s.bodyText,
      suggestionCounterpartyAccountId:
          s.voucher?.counterpartyAccountId ?? s.account?.accountId,
    );
  }
}
