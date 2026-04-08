import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/di/injection_container.dart';
import 'package:qayd/presentation/pages/notifications/notifications_cubit.dart';
import 'package:qayd/presentation/pages/notifications/notifications_page.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';

class NotificationIconButton extends StatelessWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: InjectionContainer.notificationsCubit..load(),
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          int count = 0;
          if (state is NotificationsReady) {
            count = state.notifications.where((n) => !n.isRead).length;
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                },
              ),
              if (count > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<QaydCustomColors>()!.goldAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
