import 'package:flutter/material.dart';
import 'package:qayd/domain/entities/inbox_notification.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
/// Centralized inbox for all incoming interactions (مركز الإشعارات)
/// Displaying pending requests, unread vouchers, and status shifts.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real implementation, we'd use a BLoC here. For now, mocking data.
    final mockNotifications = [
      InboxNotification(
        id: '1',
        senderName: 'شركة التقنية الحديثة',
        title: 'طلب اعتماد سند جديد',
        body: 'تم إرسال سند قبض بمبلغ 5,000 ريال. يرجى المراجعة والاعتماد.',
        isRead: false,
        receivedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        actionRoute: '/chat/123',
      ),
      InboxNotification(
        id: '2',
        senderName: 'مؤسسة البناء',
        title: 'تم اعتماد السند',
        body: 'تم اعتماد سند الصرف الخاص بك (#405).',
        isRead: true,
        receivedAt: DateTime.now().subtract(const Duration(hours: 2)),
        actionRoute: '/chat/124',
      ),
    ];

    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
      ),
      body: mockNotifications.isEmpty
          ? Center(
              child: Text(
                'لا توجد إشعارات جديدة',
                style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(SpacingTokens.md),
              itemCount: mockNotifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: SpacingTokens.sm),
              itemBuilder: (context, index) {
                final notif = mockNotifications[index];
                return _NotificationTile(notification: notif);
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final InboxNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = theme.extension<QaydCustomColors>()!;
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread ? theme.colorScheme.primary.withOpacity(0.05) : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
      child: InkWell(
        onTap: () {
          // Navigate to Deep link actionRoute
        },
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread Indicator
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 8),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: custom.goldAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              else
                const SizedBox(width: 16), // Spacer to align text

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.senderName,
                          style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          '${notification.receivedAt.hour}:${notification.receivedAt.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      notification.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
