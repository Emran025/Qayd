import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/domain/entities/inbox_notification.dart';
import 'package:qayd/presentation/components/atomic/qayd_app_bar.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/navigation/qayd_page_route.dart';
import 'package:qayd/presentation/pages/accounts/account_statement_chat_page.dart';
import 'package:qayd/presentation/pages/vouchers/tripartite_create_page.dart';
import 'package:qayd/presentation/pages/accounts/statement_chat_cubit.dart';
import 'package:qayd/presentation/pages/notifications/notifications_cubit.dart';
import 'package:qayd/presentation/pages/vouchers/voucher_create_cubit.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';

/// Centralized inbox for all incoming interactions (مركز الإشعارات)
/// Displaying pending requests, unread vouchers, and status shifts.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: InjectionContainer.notificationsCubit..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  Future<void> _openChat(BuildContext context, String accountId) async {
    await Navigator.of(context).push<void>(
      QaydPageRoute.slideFromStart<void>(
        builder: (ctx) => BlocProvider(
          create: (_) => StatementChatCubit(
            listStatement: InjectionContainer.listAccountStatementChatUseCase,
            listAccounts: InjectionContainer.listAccountsUseCase,
            getCostCenterDetails:
                InjectionContainer.getCostCenterDetailsUseCase,
            counterpartyAccountId: accountId,
          )..load(),
          child: AccountStatementChatPage(
            counterpartyAccountId: accountId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: QaydAppBar(
          title: AppStrings.messagingInboxTab, showNotifications: true),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsFailure) {
            return Center(
              child: Text(
                state.failure.messageAr,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            );
          }

          if (state is NotificationsReady) {
            final notifications = state.notifications;

            if (notifications.isEmpty) {
              return Center(
                child: Text(
                  AppStrings.thereAreNoNew,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(SpacingTokens.md),
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: SpacingTokens.sm),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _NotificationTile(
                  notification: notif,
                  onTap: () {
                    context.read<NotificationsCubit>().markAsRead(notif.id);
                    if (notif.actionRoute.startsWith('/chat/')) {
                      final accountId = notif.actionRoute.substring(6);
                      _openChat(context, accountId);
                    } else if (notif.actionRoute
                        .startsWith('/tripartite/create')) {
                      final uri = Uri.parse(notif.actionRoute);

                      // Using existing router mechanism for Tripartite page
                      Navigator.of(context).push(
                        QaydPageRoute.slideFromStart(
                          builder: (ctx) => MultiBlocProvider(
                            providers: [
                              BlocProvider<VoucherCreateCubit>(
                                create: (_) => VoucherCreateCubit(
                                  InjectionContainer.createVoucherUseCase,
                                  InjectionContainer.createTripartiteTransferUseCase,
                                ),
                              ),
                            ],
                            child: TripartiteCreatePage(
                              initialQrData: {
                                'amountMinorUnits': int.tryParse(
                                    uri.queryParameters['amount'] ?? '0'),
                                'currencyCode': uri.queryParameters['currency'],
                                'sourceAccountId':
                                    uri.queryParameters['sourceAccountId'],
                                'destAccountId':
                                    uri.queryParameters['destAccountId'],
                                'notes': uri.queryParameters['notes'],
                              },
                            ),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final InboxNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = theme.extension<QaydCustomColors>()!;
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread
          ? theme.colorScheme.primary.withOpacity(0.05)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
      child: InkWell(
        onTap: onTap,
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
                SizedBox(width: 16), // Spacer to align text

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
                    SizedBox(height: SpacingTokens.xs),
                    Text(
                      notification.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: SpacingTokens.xs),
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
