import 'package:flutter/material.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';

/// Animated pill-shaped step indicator.
class StepProgressDot extends StatelessWidget {
  const StepProgressDot({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: active
            ? ColorTokens.emerald500
            : ColorTokens.slate400.withValues(alpha: 0.4),
      ),
    );
  }
}
