import 'package:flutter/material.dart';
import 'package:qayd/presentation/components/atomic/qayd_text.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// A reusable, premium-styled dialog for the Qayd application.
/// 
/// Follows the app's design language with circular iconography, 
/// specialized typography via [QaydText], and consistent spacing.
class QaydDialog extends StatelessWidget {
  const QaydDialog({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    required this.content,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  /// The icon displayed at the top of the dialog.
  final IconData? icon;

  /// Color for the [icon]. Defaults to the secondary/tertiary theme color.
  final Color? iconColor;

  /// The title of the dialog.
  final String title;

  /// The main message or widget content. 
  /// If a [String] is passed, it is rendered as [QaydText].
  final dynamic content;

  /// Label for the primary (filled) button.
  final String? primaryActionLabel;

  /// Callback for the primary action.
  final VoidCallback? onPrimaryAction;

  /// Label for the secondary (outlined) button.
  final String? secondaryActionLabel;

  /// Callback for the secondary action.
  final VoidCallback? onSecondaryAction;

  /// Helper method to show this dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    IconData? icon,
    Color? iconColor,
    required String title,
    required dynamic content,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => QaydDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        content: content,
        primaryActionLabel: primaryActionLabel,
        onPrimaryAction: onPrimaryAction,
        secondaryActionLabel: secondaryActionLabel,
        onSecondaryAction: onSecondaryAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? scheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
      ),
      icon: icon != null
          ? Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: effectiveIconColor),
            )
          : null,
      title: QaydText(
        title,
        slot: QaydTextStyleSlot.titleLarge,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: SpacingTokens.sm),
          if (content is String)
            QaydText(
              content as String,
              slot: QaydTextStyleSlot.bodyMedium,
              color: scheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            )
          else if (content is Widget)
            content as Widget,
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(
        bottom: SpacingTokens.lg,
        left: SpacingTokens.lg,
        right: SpacingTokens.lg,
      ),
      actions: [
        if (primaryActionLabel != null || secondaryActionLabel != null)
          Row(
            children: [
              if (secondaryActionLabel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (onSecondaryAction != null) {
                        onSecondaryAction!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: SpacingTokens.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                    ),
                    child: Text(secondaryActionLabel!),
                  ),
                ),
              if (primaryActionLabel != null && secondaryActionLabel != null)
                const SizedBox(width: SpacingTokens.md),
              if (primaryActionLabel != null)
                Expanded(
                  child: FilledButton(
                    onPressed: onPrimaryAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: SpacingTokens.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                    ),
                    child: Text(primaryActionLabel!),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
