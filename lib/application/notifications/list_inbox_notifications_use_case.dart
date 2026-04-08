import 'dart:convert';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/inbox_notification.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/notification_message_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';

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
        final senderName = await _getAccountName(AccountId(msg.counterpartyAccountId));
        
        String title = 'إشعار جديد';
        String actionRoute = '/chat/${msg.counterpartyAccountId}';

        if (msg.channel == 'tripartite_event') {
          title = 'طلب إنشاء حوالة';
          try {
            final Map<String, dynamic> payload = jsonDecode(msg.rawPayloadJson!);
            final destId = payload['destAccountId'];
            final amount = payload['amountMinorUnits'];
            final cur = payload['currencyCode'];
            actionRoute = '/tripartite/create?sourceAccountId=${msg.counterpartyAccountId}&destAccountId=$destId&amount=$amount&currency=$cur';
          } catch (_) {}
        } else if (msg.channel == 'voucher_event' || msg.channel == 'conflict') {
          final Map<String, dynamic> payload = jsonDecode(msg.rawPayloadJson ?? '{}');
          final eventType = payload['event_type'] as String?;
          final hasTripartite = payload['has_tripartite_meta'] == true;
          
          switch (eventType) {
            case 'claim':
              if (hasTripartite) {
                title = 'حوالة وساطة جديدة';
              } else {
                title = msg.channel == 'conflict' ? 'تعارض في السندات' : 'سند جديد';
              }
              break;
            case 'acceptance':
              title = hasTripartite ? 'تم اعتماد الحوالة' : 'تم اعتماد السند';
              break;
            case 'rejection':
              title = hasTripartite ? 'تم رفض الحوالة' : 'تم رفض السند';
              break;
            case 'withdrawal':
              title = hasTripartite ? 'تم سحب الحوالة' : 'تم سحب السند';
              break;
            case 'settlement':
              title = hasTripartite ? 'تم سداد الحوالة' : 'تم سداد السند';
              break;
            default:
              title = hasTripartite ? 'تحديث على الحوالة' : 'تحديث على السند';
          }
        } else if (msg.bodyText.contains('طلب')) {
          title = 'طلب اعتماد سند';
        } else if (msg.bodyText.contains('اعتماد')) {
          title = 'تم اعتماد السند';
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
    return 'حساب غير معروف';
  }
}
