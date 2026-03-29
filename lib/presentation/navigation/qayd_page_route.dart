import 'package:flutter/material.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';

/// Premium slide + fade; respects RTL. Gold-tinted barrier for depth.
class QaydPageRoute {
  static Route<T> slideFromStart<T extends Object?>({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 320),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      barrierColor: ColorTokens.navy950.withValues(alpha: 0.18),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final begin = rtl ? const Offset(0.06, 0) : const Offset(-0.06, 0);
        final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.85, curve: Curves.easeOut),
        );
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }
}
