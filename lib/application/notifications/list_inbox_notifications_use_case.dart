import 'dart:convert';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/inbox_notification.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


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

        String title = AppStringsAr.newNotification;
        String actionRoute = '/chat/${msg.counterpartyAccountId}';

        if (msg.channel == 'tripartite_event') {
          title = AppStringsAr.requestToCreateA;
          try {
            final Map<String, dynamic> payload =
                jsonDecode(msg.rawPayloadJson!);
            final destId = payload['destAccountId'];
            final amount = payload['amountMinorUnits'];
            final cur = payload['currencyCode'];
            actionRoute =
                '/tripartite/create?sourceAccountId=${msg.counterpartyAccountId}&destAccountId=$destId&amount=$amount&currency=$cur';
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
                title = AppStringsAr.newBrokerageTransfer;
              } else {
                title =
                    msg.channel == 'conflict' ? AppStringsAr.bondConflict : AppStringsAr.newBond;
              }
              break;
            case 'acceptance':
              title = hasTripartite ? AppStringsAr.theTransferHasBeen : AppStringsAr.theBondHasBeen3;
              break;
            case 'rejection':
              title = hasTripartite ? AppStringsAr.theTransferWasRejected : AppStringsAr.bondWasDenied;
              break;
            case 'withdrawal':
              title = hasTripartite ? AppStringsAr.theTransferHasBeen2 : AppStringsAr.theBondHasBeen2;
              break;
            case 'settlement':
              title = hasTripartite ? AppStringsAr.theTransferHasBeen1 : AppStringsAr.theBondHasBeen;
              break;
            default:
              title = hasTripartite ? AppStringsAr.updateOnTheTransfer : AppStringsAr.updateOnTheBond;
          }
        } else if (msg.bodyText.contains(AppStringsAr.toRequest)) {
          title = AppStringsAr.requestToApproveA;
        } else if (msg.bodyText.contains(AppStringsAr.adoption)) {
          title = AppStringsAr.theBondHasBeen3;
        }

        notifications.add(
          InboxNotification(
            id: msg.id,
            senderName: senderName,
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
    return AppStringsAr.unknownAccount;
  }
}
