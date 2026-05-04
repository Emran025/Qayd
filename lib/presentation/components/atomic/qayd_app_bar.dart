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
    this.showNotifications = false,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showNotifications;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).extension<QaydCustomColors>()!.goldAccent;

    final List<Widget> effectiveActions = [...(actions ?? [])];
    if (showNotifications) {
      effectiveActions.add(const NotificationIconButton());
    }

    // Gold decorative underline used in both cases
    final goldUnderline = Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            gold.withValues(alpha: 0.85),
            gold.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );

    final PreferredSizeWidget effectiveBottom;
    if (bottom != null) {
      effectiveBottom = _CombinedPreferredSize(
        top: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: goldUnderline,
        ),
        bottom: bottom!,
      );
    } else {
      effectiveBottom = PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: goldUnderline,
      );
    }

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null) {
      final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
      final bool canPop = parentRoute?.canPop ?? false;
      
      if (!canPop) {
        effectiveLeading = Builder(
          builder: (builderContext) {
            bool foundDrawer = false;
            builderContext.visitAncestorElements((element) {
              if (element.widget is Scaffold) {
                final state = (element as StatefulElement).state as ScaffoldState;
                if (state.hasDrawer) {
                  foundDrawer = true;
                  return false; // Found
                }
              }
              return true; // Keep searching
            });

            if (foundDrawer) {
              return IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () {
                  ScaffoldState? targetScaffold;
                  builderContext.visitAncestorElements((element) {
                    if (element.widget is Scaffold) {
                      final state = (element as StatefulElement).state as ScaffoldState;
                      if (state.hasDrawer) {
                        targetScaffold = state;
                        return false;
                      }
                    }
                    return true;
                  });
                  targetScaffold?.openDrawer();
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              );
            }
            return const SizedBox.shrink();
          },
        );
      }
    }

    return AppBar(
      leading: effectiveLeading,
      title: QaydText(
        title,
        slot: QaydTextStyleSlot.titleLarge,
      ),
      centerTitle: centerTitle,
      actions: effectiveActions,
      bottom: effectiveBottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 3));
}

/// Helper widget to combine two PreferredSizeWidgets (like TabBar + Underline)
class _CombinedPreferredSize extends StatelessWidget
    implements PreferredSizeWidget {
  const _CombinedPreferredSize({required this.top, required this.bottom});

  final PreferredSizeWidget top;
  final PreferredSizeWidget bottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        top,
        bottom,
      ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(top.preferredSize.height + bottom.preferredSize.height);
}
