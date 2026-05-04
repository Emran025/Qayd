import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';

class QaydFloatingActionButton extends StatelessWidget {
  const QaydFloatingActionButton({
    super.key,
    required this.onPressed,
    this.child,
    this.heroTag,
    this.elevation,
    this.shape,
  })  : label = null,
        icon = null;

  const QaydFloatingActionButton.extended({
    super.key,
    required this.onPressed,
    this.icon,
    required this.label,
    this.heroTag,
    this.elevation,
    this.shape,
  }) : child = null;

  final VoidCallback onPressed;
  final Widget? icon;
  final Widget? label;
  final Widget? child;
  final String? heroTag;
  final double? elevation;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<QaydCustomColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    if (!isDark) {
      if (label != null) {
        return FloatingActionButton.extended(
          heroTag: heroTag,
          onPressed: onPressed,
          icon: icon,
          label: label!,
          elevation: elevation,
          shape: shape,
          backgroundColor: customColors.goldAccent,
          foregroundColor: ColorTokens.navy950,
        );
      }
      return FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        elevation: elevation,
        shape: shape,
        backgroundColor: customColors.goldAccent,
        foregroundColor: ColorTokens.navy950,
        child: child ?? icon,
      );
    }

    // Dark mode glassmorphism
    final fabShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RadiusTokens.lg),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(
          color: customColors.goldAccent.withValues(alpha: 0.4),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Theme(
            data: theme.copyWith(
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: customColors.goldAccent.withValues(alpha: 0.08),
                elevation: 0,
                hoverElevation: 0,
                focusElevation: 0,
                highlightElevation: 0,
                shape: fabShape,
              ),
            ),
            child: label != null
                ? FloatingActionButton.extended(
                    heroTag: heroTag,
                    onPressed: onPressed,
                    icon: icon,
                    label: label!,
                    elevation: 0,
                    hoverElevation: 0,
                    focusElevation: 0,
                    highlightElevation: 0,
                    foregroundColor: customColors.goldAccent,
                  )
                : FloatingActionButton(
                    heroTag: heroTag,
                    onPressed: onPressed,
                    elevation: 0,
                    hoverElevation: 0,
                    focusElevation: 0,
                    highlightElevation: 0,
                    foregroundColor: customColors.goldAccent,
                    child: child ?? icon,
                  ),
          ),
        ),
      ),
    );
  }
}
