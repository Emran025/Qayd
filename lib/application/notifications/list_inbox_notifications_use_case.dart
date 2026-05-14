import 'dart:convert';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/inbox_notification.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// Fetches real inbound notifications from the local database.
final class ListInboxNotificationsUseCase {
  const ListInboxNotificationsUseCase({
    required this.notificationRepo,
    required this.accountRepository,
  });

  final NotificationMessageRepository notificationRepo;
  final AccountRepository accountRepository;

  Future<Result<List<InboxNotification>>> call() async {
    try {
      final r = await notificationRepo.listAllUnprocessed(limit: 100);
      if (r.isFailure) return FailureResult(r.failureOrNull!);

      final messages = r.valueOrNull!;
      final notifications = <InboxNotification>[];

      for (final msg in messages) {
        final senderName =
            await _getAccountName(AccountId(msg.counterpartyAccountId));

        String title = AppStrings.newNotification;
        String actionRoute = '/chat/${msg.counterpartyAccountId}';
        // May be overridden below when no account exists yet (e.g. onboarding).
        String? overrideSenderName;

        if (msg.channel == 'counterparty_request') {
          title = AppStrings.counterpartyOnboardingRequestTitle;
          try {
            final Map<String, dynamic> raw =
                jsonDecode(msg.rawPayloadJson ?? '{}');
            final sPhone = raw['sender_phone'] as String?;
            final sPk = raw['sender_pk'] as String?;
            final sWa = raw['sender_whatsapp'] as String?;

            // Prefer the real registered name resolved from the server at
            // staging time; fall back to phone / whatsapp / pk fragment.
            final resolvedName = raw['sender_name'] as String?;
            overrideSenderName = resolvedName?.isNotEmpty == true
                ? resolvedName!
                : sPhone?.isNotEmpty == true
                    ? sPhone!
                    : sWa?.isNotEmpty == true
                        ? sWa!
                        : (sPk?.isNotEmpty == true
                            ? sPk!.substring(0, 12)
                            : '');

            actionRoute =
                '/onboard/counterparty?phone=${Uri.encodeComponent(sPhone ?? '')}'
                '&pk=${Uri.encodeComponent(sPk ?? '')}'
                '&whatsapp=${Uri.encodeComponent(sWa ?? '')}'
                '&name=${Uri.encodeComponent(overrideSenderName)}';
          } catch (_) {}
        } else if (msg.channel == 'tripartite_event') {
          title = AppStrings.transferRequestReceivedTitle;
          try {
            final Map<String, dynamic> payload =
                jsonDecode(msg.rawPayloadJson!);
            final destId = payload['destAccountId'];
            final amount = payload['amountMinorUnits'];
            final cur = payload['currencyCode'];
            final notes = payload['notes'] as String?;
            
            actionRoute =
                '/tripartite/create?sourceAccountId=${msg.counterpartyAccountId}&destAccountId=$destId&amount=$amount&currency=$cur';
            if (notes != null && notes.isNotEmpty) {
              actionRoute += '&notes=${Uri.encodeComponent(notes)}';
            }
          } catch (_) {}
        } else if (msg.channel == 'voucher_event' ||
            msg.channel == 'conflict') {
          final Map<String, dynamic> payload =
              jsonDecode(msg.rawPayloadJson ?? '{}');
          final eventType = payload['event_type'] as String?;
          final hasTripartite = payload['has_tripartite_meta'] == true;

          switch (eventType) {
            case 'claim':
              if (hasTripartite) {
                title = AppStrings.newBrokerageTransfer;
              } else {
                title =
                    msg.channel == 'conflict' ? AppStrings.bondConflict : AppStrings.newBond;
              }
              break;
            case 'acceptance':
              title = hasTripartite ? AppStrings.theTransferHasBeen : AppStrings.theBondHasBeen3;
              break;
            case 'rejection':
              title = hasTripartite ? AppStrings.theTransferWasRejected : AppStrings.bondWasDenied;
              break;
            case 'withdrawal':
              title = hasTripartite ? AppStrings.theTransferHasBeen2 : AppStrings.theBondHasBeen2;
              break;
            case 'settlement':
              title = hasTripartite ? AppStrings.theTransferHasBeen1 : AppStrings.theBondHasBeen;
              break;
            default:
              title = hasTripartite ? AppStrings.updateOnTheTransfer : AppStrings.updateOnTheBond;
          }
        } else if (msg.bodyText.contains(AppStrings.toRequest)) {
          title = AppStrings.requestToApproveA;
        } else if (msg.bodyText.contains(AppStrings.adoption)) {
          title = AppStrings.theBondHasBeen3;
        }

        notifications.add(
          InboxNotification(
            id: msg.id,
            senderName: overrideSenderName ?? senderName,
            title: title,
            body: msg.bodyText,
            isRead: msg.processed,
            receivedAt: msg.createdAt,
            actionRoute: actionRoute,
          ),
        );
      }

      // Sort by recency (handled by repo, but doesn't hurt)
      notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

      return Success(notifications);
    } catch (e) {
      return FailureResult(failureFromDomainException(e));
    }
  }

  Future<String> _getAccountName(AccountId id) async {
    final r = await accountRepository.getById(id);
    if (r.isSuccess) {
      return r.valueOrNull!.name;
    }
    return AppStrings.unknownAccount;
  }
}
