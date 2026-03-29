import 'package:flutter/material.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/presentation/theme/qayd_theme_extensions.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';

/// Voucher lifecycle badge (draft / confirmed / settled) with theme tokens and RTL-safe padding.
class QaydBadge extends StatelessWidget {
  const QaydBadge({
    super.key,
    required this.state,
  });

  final VoucherState state;

  static String _label(VoucherState state) {
    return switch (state) {
      VoucherState.draft => AppStringsAr.voucherStateDraft,
      VoucherState.confirmed => AppStringsAr.voucherStateConfirmed,
      VoucherState.settled => AppStringsAr.voucherStateSettled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<QaydCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final (Color bg, Color fg, bool dashed) = switch (state) {
      VoucherState.draft => (custom.draftState, custom.badgeOnDraft, true),
      VoucherState.confirmed => (custom.confirmedState, custom.badgeOnConfirmed, false),
      VoucherState.settled => (custom.settledState, custom.badgeOnSettled, false),
    };

    final label = _label(state);
    final text = Text(
      label,
      style: textTheme.labelMedium?.copyWith(
        color: fg,
        fontWeight: FontWeight.w600,
      ),
    );

    final padding = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm + 2,
        vertical: SpacingTokens.xs,
      ),
      child: text,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
        border: dashed
            ? null
            : Border.all(color: fg.withValues(alpha: 0.35), width: 1),
      ),
      child: dashed
          ? CustomPaint(
              painter: _DashedRoundedRectPainter(
                color: fg.withValues(alpha: 0.65),
                radius: RadiusTokens.sm,
              ),
              child: padding,
            )
          : padding,
    );
  }
}

/// Dashed outline for draft state (design system §3.2).
final class _DashedRoundedRectPainter extends CustomPainter {
  _DashedRoundedRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(r);
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = (d + dash).clamp(0.0, metric.length);
        final extract = metric.extractPath(d, end);
        canvas.drawPath(
          extract,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
