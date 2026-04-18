import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/notifications/list_inbox_notifications_use_case.dart';
import 'package:qayd/application/suggestions/mark_notification_message_processed_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/inbox_notification.dart';

/// Sealed state hierarchy for the Notification Center.
sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

final class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

final class NotificationsReady extends NotificationsState {
  const NotificationsReady(this.notifications);

  final List<InboxNotification> notifications;

  @override
  List<Object?> get props => [notifications];
}

final class NotificationsFailure extends NotificationsState {
  const NotificationsFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._listInbox, this._markProcessed)
      : super(const NotificationsInitial());

  final ListInboxNotificationsUseCase _listInbox;
  final MarkNotificationMessageProcessedUseCase _markProcessed;

  Future<void> load() async {
    emit(const NotificationsLoading());
    final r = await _listInbox();
    if (isClosed) return;

    if (r.isSuccess) {
      emit(NotificationsReady(r.valueOrNull!));
    } else {
      emit(NotificationsFailure(r.failureOrNull!));
    }
  }

  void markAsRead(String id) {
    if (isClosed) return;
    final s = state;
    if (s is NotificationsReady) {
      // Persist to database so the read state survives app restarts.
      _markProcessed(id).then((result) {
        if (result.isFailure) {
          debugPrint('Failed to persist notification read state for $id');
        }
      });

      final updated = s.notifications.map((n) {
        if (n.id == id) {
          return InboxNotification(
            id: n.id,
            senderName: n.senderName,
            title: n.title,
            body: n.body,
            isRead: true,
            receivedAt: n.receivedAt,
            actionRoute: n.actionRoute,
          );
        }
        return n;
      }).toList();
      emit(NotificationsReady(updated));
    }
  }
}
