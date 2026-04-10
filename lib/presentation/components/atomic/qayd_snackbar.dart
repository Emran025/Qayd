import 'package:flutter/material.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

enum QaydSnackBarType { success, error, info, warning }

class QaydSnackBar {
  static void show(
    BuildContext context,
    String message, {
    QaydSnackBarType type = QaydSnackBarType.info,
    IconData? customIcon,
    Duration duration = const Duration(seconds: 4),
  }) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final scheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case QaydSnackBarType.success:
        backgroundColor = custom.confirmedState.withValues(alpha: 0.15);
        iconColor = custom.confirmedState;
        icon = customIcon ?? Icons.check_circle_rounded;
        break;
      case QaydSnackBarType.error:
        backgroundColor = ColorTokens.errorDeep.withValues(alpha: 0.15);
        iconColor = ColorTokens.errorDeep;
        icon = customIcon ?? Icons.cancel_rounded;
        break;
      case QaydSnackBarType.warning:
        backgroundColor = custom.draftState.withValues(alpha: 0.15);
        iconColor = custom.draftState;
        icon = customIcon ?? Icons.warning_rounded;
        break;
      // case QaydSnackBarType.info:
      //   backgroundColor = scheme.primaryContainer;
      //   iconColor = scheme.primary;
      //   icon = customIcon ?? Icons.info_rounded;
      //   break;
      default:
        backgroundColor = scheme.primaryContainer;
        iconColor = scheme.primary;
        icon = customIcon ?? Icons.info_rounded;
        break;
    }

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      duration: duration,
      content: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm + 4,
          vertical: SpacingTokens.sm + 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.xs + 2),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: SpacingTokens.md),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
              ),
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
