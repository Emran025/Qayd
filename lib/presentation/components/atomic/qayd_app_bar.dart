import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/pages/notifications/widgets/notification_icon_button.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

class QaydAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QaydAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showNotifications = true,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showNotifications;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    final List<Widget> effectiveActions = [...(actions ?? [])];
    if (showNotifications) {
      effectiveActions.add(const NotificationIconButton());
    }

    return AppBar(
      leading: leading,
      title: QaydText(
        title,
        slot: QaydTextStyleSlot.titleLarge,
      ),
      centerTitle: centerTitle,
      actions: effectiveActions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                gold.withValues(alpha: 0.85),
                gold.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 3);
}
